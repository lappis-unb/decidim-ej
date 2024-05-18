# frozen_string_literal: true
require 'securerandom'
require 'httparty'

module Decidim
  module Ej
    class Unauthorized < StandardError
    end

    class Forbidden < StandardError
    end

    class UnknownError < StandardError
    end

    class ClientApi
      include HTTParty

      VOTE_OPTIONS = {
        agree: 1,
        disagree: -1,
        skip: 0
      }.freeze

      def initialize(user, component)
        @user = user
        @host = component.host
        @conversation_id = component.conversation_id
        @routes = {
          users: "/api/v1/users/",
          login: "/api/v1/login/",
          conversations: "/api/v1/conversations/",
          votes: "/api/v1/votes/"
        }
      end

      def login_route
        "#{@host}#{@routes[:login]}"
      end

      def new_user_route
        "#{@host}#{@routes[:users]}"
      end

      def conversation_route
        "#{@host}#{@routes[:conversations]}#{@conversation_id}"
      end

      def comment_route
        "#{@host}#{@routes[:conversations]}#{@conversation_id}/random-comment"
      end

      def vote_route
        "#{@host}#{@routes[:votes]}"
      end

      def decidim_user_name
        "decidim-#{@user.name}"
      end

      def decidim_user_email
        "decidim-#{@user.email}"
      end

      def decidim_password
        "decidim-#{@user.name}-#{@user.email}"
      end

      def new_user_data
        {
          name: decidim_user_name,
          email: decidim_user_email,
          password: decidim_password,
          password_confirm: decidim_password
        }
      end

      def user_data
        {
          email: decidim_user_email,
          password: decidim_password
        }
      end

      def fetch_conversation
        fire_action_request(:conversation)
      end

      def post_vote
        fire_action_request(:vote)
      end

      def fetch_next_comment
        fire_action_request(:next_comment)
      end

      def cached_token
        Rails.cache.read(user_token_cache_identifier)
      end

      private

      def headers
        { 'Authorization' => "Token #{cached_token}" }
      end

      def fire_action_request(action, *args, attempt: 0)
        raise Decidim::Ej::UnknownError if attempt > 5

        begin
          authenticate
          send(action, *args)
        rescue Decidim::Ej::Forbidden
          invalidate_cached_token!
          fire_action_request(action, *args, attempt: attempt + 1)
        rescue Decidim::Ej::Unauthorized
          invalidate_user_registration!
          fire_action_request(action, *args, attempt: attempt + 1)
        end
      end

      def authenticate
        return create_user unless @user.has_ej_account?
        return cached_token if cached_token.present?

        response = self.class.post(
          login_route,
          body: JSON.generate(user_data),
          headers: { 'Content-Type' => 'application/json' }
        )

        raise Unauthorized if response.code == 401
        raise UnknownError unless response.code == 200

        body = JSON.parse response.body

        # TODO: Receive expiration time in the response and properly set here
        set_cached_token(body["token"])
      end

      def vote(choice, comment_id)
        request_body = {
          choice: VOTE_OPTIONS[choice.to_sym],
          comment: comment_id, channel:
          "opinion_component"
        }
        response = self.class.post(vote_route, body: request_body, headers: headers)

        raise Unauthorized if response.code == 401
        raise Forbidden if response.code == 403
        raise UnknownError unless response.code.in?([200, 201])

        response
      end

      def conversation
        response = self.class.get(conversation_route)

        raise UnknownError unless response.code == 200

        JSON.parse response.body
      end

      def next_comment
        response = self.class.get(comment_route, headers: headers)

        raise Unauthorized if response.code == 401
        raise Forbidden if response.code == 403
        raise UnknownError, "comment could not be retrieved" unless response.code == 200

        body = JSON.parse response.body
        body = { "content" => "You have voted on all comments. Thank you for the participation." } unless body["content"]

        body
      end

      def set_cached_token(value, expiration: nil)
        expiration = expiration.presence || 3600
        Rails.cache.write(user_token_cache_identifier, value, expires_in: expiration.seconds)
      end

      def invalidate_cached_token!
        Rails.cache.write(user_token_cache_identifier, nil)
      end

      def user_token_cache_identifier
        "ej/users/#{@user.id}/token"
      end

      def create_user
        response = self.class.post(
          new_user_route,
          body: JSON.generate(new_user_data),
          headers: { 'Content-Type' => 'application/json' }
        )

        @user.update_column(:has_ej_account, true)

        raise Decidim::Ej::Forbidden if response.code == 400

        body = JSON.parse response.body

        # TODO: Receive expiration time in the response and properly set here
        set_cached_token(body["token"])
      end

      def invalidate_user_registration!
        @user.update_column(:has_ej_account, false)
      end
    end
  end
end
