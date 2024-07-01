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
          votes: "/api/v1/votes/",
          comments: "/api/v1/comments/"
        }
      end

      def fetch_conversation
        fire_action_request(:conversation)
      end

      def fetch_conversations
        fire_action_request(:conversations)
      end

      def fetch_user_comments
        fire_action_request(:user_comments)
      end

      def fetch_next_comment
        fire_action_request(:next_comment)
      end

      def post_vote(choice, comment_id)
        fire_action_request(:vote, choice, comment_id)
      end

      def post_comment(content)
        fire_action_request(:comment, content)
      end

      private

      def cached_token
        # Read the token from the cache
        Rails.cache.read(user_token_cache_identifier)
      end

      def headers
        # Set the authorization header with the cached token
        {
          Authorization: "Bearer #{cached_token}"
        }
      end

      def fire_action_request(action, *args, attempt: 1)
        if attempt > 2
          Rails.logger.error "Authentication failed twice in EJ action #{action} for user #{@user.name}."
          raise Decidim::Ej::RequestError
        end

        # Authenticate the user
        authenticate

        begin
          send(action, *args)
        rescue Decidim::Ej::Unauthorized
          invalidate_cached_token!
          fire_action_request(action, *args, attempt: attempt + 1)
        end
      end

      def authenticate
        # Create user if the user does not have an EJ account
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
        set_cached_token(body["access_token"])
      end

      def vote(choice, comment_id)
        # Prepare the request body with the vote choice and comment ID
        request_body = {
          choice: VOTE_OPTIONS[choice.to_sym],
          comment: comment_id, channel:
          "opinion_component"
        }

        # Make a POST request to the vote endpoint
        response = self.class.post(vote_route, body: request_body, headers: headers)

        raise Unauthorized if response.code == 401
        raise RequestError unless response.code.in?([200, 201])

        response
      end

      def get_user_stats(response)
        response_user_stats = self.class.get(user_statistics_route, headers: headers)

        participation_ratio = response_user_stats['participation_ratio'] || 0
        formatted_user_stats = {
          'percent': "#{format('%.2f%%', participation_ratio * 100)}",
          'comments': "#{response_user_stats['comments']} de #{response_user_stats['total_comments']}"
        }

        response_body = JSON.parse(response.body)
        response_body['user_stats'] = formatted_user_stats

        new_response = response.dup
        new_response.instance_variable_set(:@body, response_body.to_json)
        new_response
      end

      def conversation
        # Make a GET request to the conversation endpoint
        response = self.class.get(conversation_route)
        response = get_user_stats(response)

        raise RequestError unless response.code == 200

        JSON.parse(response.body)
      end

      def conversations
        response = self.class.get(
          conversations_route,
          headers: headers
        )
        raise Unauthorized if response.code == 401
        raise RequestError unless response.code == 200

        JSON.parse(response.body)
      end

      def user_comments
        response = self.class.get(
          comment_route,
          headers: headers
        )

        raise Unauthorized if response.code == 401
        raise RequestError unless response.code == 200

        JSON.parse(response.body)
      end

      def next_comment
        # Make a GET request to fetch the next comment
        response = self.class.get(random_comment_route, headers: headers)

        raise Unauthorized if response.code == 401
        raise RequestError, "O comentário não pôde ser recuperado." unless response.code == 200

        body = JSON.parse response.body
        body = { "content" => "Você já votou em todos os comentários. Obrigada pela sua participação!" } unless body["content"].present?

        body
      end

      def comment(content)
        body = {
          content: content,
          conversation: @conversation_id,
          status: :pending
        }.to_json

        headers = self.headers.merge({ 'Content-Type': 'application/json' })

        response = self.class.post(
          comment_route,
          headers: headers,
          body: body
        )

        raise Unauthorized if response.code == 401
        raise RequestError unless response.code.in? [200, 201]

        JSON.parse(response.body)
      end

      def set_cached_token(value, expiration: nil)
        expiration = expiration.presence || 3600
        Rails.cache.write(user_token_cache_identifier, value, expires_in: expiration.seconds)
      end

      def invalidate_cached_token!
        Rails.cache.write(user_token_cache_identifier, nil)
      end

      def user_token_cache_identifier
        # Generate a unique cache key for the user's token
        "ej/users/#{@user.id}/token"
      end

      def create_user
        # Make a POST request to create a new user
        response = self.class.post(
          new_user_route,
          body: JSON.generate(new_user_data),
          headers: { 'Content-Type' => 'application/json' }
        )

        # Update the user's EJ account status
        @user.update_column(:has_ej_account, true)

        raise Decidim::Ej::RequestError unless response.code == 200

        body = JSON.parse response.body

        # TODO: Receive expiration time in the response and properly set here
        set_cached_token(body["access_token"])
      end

      def new_user_data
        # Prepare the data for creating a new user
        {
          name: decidim_user_name,
          email: decidim_user_email,
          password: decidim_password,
          password_confirm: decidim_password
        }
      end

      def user_data
        # Prepare the login data
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

      def user_statistics_route
        "#{@host}#{@routes[:conversations]}#{@conversation_id}/user-statistics/"
      end

      def conversations_route
        "#{@host}#{@routes[:conversations]}"
      end

      def random_comment_route
        "#{@host}#{@routes[:conversations]}#{@conversation_id}/random-comment"
      end

      def vote_route
        "#{@host}#{@routes[:votes]}"
      end

      def comment_route
        "#{@host}#{@routes[:comments]}"
      end

      def decidim_user_name
        "decidim-#{@user.name}"
      end

      def decidim_user_email
        "decidim-#{@user.email}"
      end

      def decidim_password
        return AttributeEncryptor.decrypt(@user.encrypted_ej_password) if @user.encrypted_ej_password

        new_password = SecureRandom.hex(12)

        @user.encrypted_ej_password = AttributeEncryptor.encrypt(new_password)
        @user.save!

        new_password
      end
    end
  end
end
