# frozen_string_literal: true
require 'securerandom'
require 'httparty'

module Decidim
  module Ej
    class Unauthorized < StandardError
    end

    class RequestError < StandardError
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

      def fetch_conversation
        fire_action_request(:conversation)
      end

      def post_vote(choice, comment_id)
        fire_action_request(:vote, choice, comment_id)
      end

      def fetch_next_comment
        fire_action_request(:next_comment)
      end

      private

      def cached_token
        Rails.cache.read(user_token_cache_identifier)
      end

      def headers
        { 'Authorization' => "Token #{cached_token}" }
      end

      def fire_action_request(action, *args, attempt: 1)
        if attempt > 2
          Rails.logger.error "Authentication failed twice in EJ action #{action} for user #{@user.name}."
          raise Decidim::Ej::RequestError
        end

        authenticate

        begin
          send(action, *args)
        rescue Decidim::Ej::Unauthorized
          invalidate_cached_token!
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

        unless response.code == 200
          Rails.logger.error "Error while getting EJ token for user #{@user.name}. Response: #{response}"
          raise RequestError unless response.code == 200
        end

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
        raise RequestError unless response.code.in?([200, 201])

        response
      end

      def conversation
        response = self.class.get(conversation_route)

        raise RequestError unless response.code == 200

        JSON.parse response.body
      end

      def next_comment
        response = self.class.get(comment_route, headers: headers)

        raise Unauthorized if response.code == 401
        raise RequestError, "comment could not be retrieved" unless response.code == 200

        body = JSON.parse response.body
        body = { "content" => "You have voted on all comments. Thank you for the participation." } unless body["content"].present?

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

        raise Decidim::Ej::RequestError unless response.code == 200

        body = JSON.parse response.body

        # TODO: Receive expiration time in the response and properly set here
        set_cached_token(body["token"])
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
    end
  end
end
