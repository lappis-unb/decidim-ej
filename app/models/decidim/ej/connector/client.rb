# frozen_string_literal: true

require 'httparty'

module Decidim
  module Ej
    module Connector
      # Responsible to connect with EJ through its API, mostly using user
      # credentials in authorization
      #
      class Client
        include Endpoints

        VOTE_OPTIONS = {
          agree: 1,
          disagree: -1,
          skip: 0
        }.freeze

        def initialize(host, user)
          @host = host
          @user = user
        end

        def fetch_conversation(conversation_id)
          fire_action_request(:conversation, conversation_id)
        end

        def fetch_conversations
          fire_action_request(:conversations)
        end

        def fetch_user_comments
          fire_action_request(:user_comments)
        end

        def fetch_next_comment(conversation_id)
          fire_action_request(:next_comment, conversation_id)
        end

        def post_vote(choice, comment_id)
          fire_action_request(:vote, choice, comment_id)
        end

        def post_comment(conversation_id, content)
          fire_action_request(:comment, conversation_id, content)
        end

        def link_user_account(secret_id, external_id)
          raise Exceptions::UserCannotBeLinked if user.has_ej_account?

          create_user(secret_id, external_id)
        end

        private

        attr_reader :host, :user

        def user_statistics(conversation_id)
          user_specific_data_response = HTTParty.get("#{host}#{user_statistics_path(conversation_id)}", headers: authorization_headers)
          raise Exceptions::Unauthorized if user_specific_data_response.code == 401

          unless user_specific_data_response.success?
            Rails.logger.error("Error while getting user conversation statistics data. Response: #{user_specific_data_response}")
            raise Exceptions::RequestError
          end

          user_specific_data_response
        end

        def conversation(conversation_id)
          core_data_response = HTTParty.get("#{host}#{conversations_path(conversation_id)}", headers: authorization_headers)
          raise Exceptions::Unauthorized if core_data_response.code == 401

          unless core_data_response.success?
            Rails.logger.error("Error while getting conversation data. Response: #{core_data_response}")
            raise Exceptions::RequestError
          end

          user_specific_data_response = user_statistics(conversation_id)

          response = core_data_response.with_indifferent_access
          response[:user_stats] = user_specific_data_response.with_indifferent_access

          response
        end

        def conversations
          response = HTTParty.get(
            "#{host}#{conversations_path}",
            headers: authorization_headers
          )

          raise Exceptions::Unauthorized if response.code == 401
          raise Exceptions::RequestError unless response.success?

          conversations = JSON.parse(response.body)
          conversations.each do |conversation|
            response_user_stats = user_statistics(conversation["id"])
            participation_ratio = response_user_stats['participation_ratio'] || 0
            formatted_user_stats = {
              percent: format('%.2f%%', participation_ratio * 100).to_s,
              comments: response_user_stats['comments'] == 0 ? "Você ainda não votou nesta enquete" : "Você votou em #{response_user_stats["comments"]} de #{response_user_stats["total_comments"]} comentários"
            }

            conversation["user_stats"] = formatted_user_stats
          end

          conversations
        end

        def user_comments
          response = HTTParty.get(
            "#{host}#{comments_path}",
            headers: authorization_headers
          )

          raise Exceptions::Unauthorized if response.code == 401
          raise Exceptions::RequestError unless response.success?

          JSON.parse(response.body)
        end

        def next_comment(conversation_id)
          response = HTTParty.get(
            "#{host}#{random_comment_path(conversation_id)}",
            headers: authorization_headers
          )

          raise Exceptions::Unauthorized if response.code == 401
          raise Exceptions::RequestError unless response.success?

          response.with_indifferent_access
        end

        def vote(choice, comment_id)
          request_body = {
            choice: VOTE_OPTIONS[choice.to_sym],
            comment: comment_id,
            channel: :opinion_component
          }

          request_headers = content_type_headers.merge(authorization_headers)

          response = HTTParty.post(
            "#{host}#{votes_path}",
            body: request_body.to_json,
            headers: request_headers
          )

          raise Exceptions::Unauthorized if response.code == 401
          raise Exceptions::RequestError unless response.success?

          response.with_indifferent_access
        end

        def comment(conversation_id, content)
          request_body = {
            content: content,
            conversation: conversation_id,
            status: :pending
          }

          request_headers = content_type_headers.merge(authorization_headers)

          response = HTTParty.post(
            "#{host}#{comments_path}",
            body: request_body.to_json,
            headers: request_headers
          )

          raise Exceptions::Unauthorized if response.code == 401
          raise Exceptions::RequestError unless response.success?

          response.with_indifferent_access
        end

        def cached_token
          # Read the token from the cache
          Rails.cache.read(user_token_cache_identifier)
        end

        def set_cached_token(value, expiration: nil)
          expiration = expiration.presence || 3600
          Rails.cache.write(user_token_cache_identifier, value, expires_in: expiration.seconds)
        end

        def invalidate_cached_token!
          Rails.cache.write(user_token_cache_identifier, nil)
        end

        # Generate a unique cache key for the user's token
        def user_token_cache_identifier
          "ej/users/#{user.id}/token"
        end

        # Authorization header with the cached token
        def authorization_headers
          { Authorization: "Bearer #{cached_token}" }
        end

        # Content type headers for post requests
        def content_type_headers
          { 'Content-Type': 'application/json' }
        end

        def fire_action_request(action, *args, attempt: 1)
          if attempt > 2
            Rails.logger.error "Authentication failed twice in EJ action #{action} for user #{user.name}."
            raise Exceptions::RequestError
          end

          # Authenticate the user
          authenticate

          begin
            send(action, *args)
          rescue Exceptions::Unauthorized
            invalidate_cached_token!
            fire_action_request(action, *args, attempt: attempt + 1)
          end
        end

        def authenticate
          return create_user unless user.has_ej_account?
          return cached_token if cached_token.present?

          body = {
            email: "decidim-#{user.email}",
            password: user.ej_password
          }

          response = HTTParty.post(
            "#{host}#{login_path}",
            body: body.to_json,
            headers: content_type_headers
          )

          unless response.success?
            Rails.logger.error "Error while getting EJ token for user #{user.name}. Response: #{response}"
            raise Exceptions::RequestError
          end

          # TODO: Receive expiration time in the response and properly set here
          set_cached_token(response["access_token"])
        end

        def create_user(secret_id = nil, external_id = nil)
          # (Re)Generate a fresh user password for EJ. Password is a random hex.
          if external_id.blank?
            user.generate_random_ej_password!
          else
            user.generate_ej_password_with_external_id(external_id)
          end

          body = {
            name: "decidim-#{user.name}",
            email: "decidim-#{user.email}",
            password: user.ej_password,
            password_confirm: user.ej_password
          }.with_indifferent_access

          body[:secret_id] = secret_id if secret_id

          # Make a POST request to create a new user
          response = HTTParty.post(
            "#{host}#{sign_up_path}",
            body: body.to_json,
            headers: content_type_headers
          )

          unless response.success?
            Rails.logger.error "Error while creating user #{user}. Response: #{response}"
            raise Exceptions::RequestError
          end

          # Update the user's EJ account status if everything is ok
          user.update_column(:has_ej_account, true)
          set_cached_token(response["access_token"])
        end
      end
    end
  end
end
