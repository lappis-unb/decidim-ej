# frozen_string_literal: true
require 'securerandom'
require 'httparty'

module Decidim
  module Ej
    class ClientApi
      include HTTParty

      attr_reader :new_user_route, :new_user_data, :token, :decidim_user_name, :decidim_user_email, :decidim_password, :user_data, :conversation_route, :conversation, :headers

      def initialize(user, component)
        @user = user
        @host = component.host
        @conversation_id = component.conversation_id
        @routes = {
          "users": "/api/v1/users/",
          "login": "/api/v1/login/",
          "conversations": "/api/v1/conversations/",
          "votes": "/api/v1/votes/"
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

      def comment_route(*args)
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
        password = SecureRandom.hex
        {
          "name": self.decidim_user_name,
          "email": self.decidim_user_email,
          "password": self.decidim_password,
          "password_confirm": self.decidim_password
        }
      end

      def user_data
        {
          "email": self.decidim_user_email,
          "password": self.decidim_password
        }
      end

      def get_conversation
        response = self.class.get(self.conversation_route)
        if response.code == 200
          return JSON.parse response.body
        else
          raise "conversation not found"
        end
      end

      def headers
        {'Authorization': "Token #{@token}"}
      end

      def vote(choice, comment_id)
        votes_options = {"agree": 1, "disagree": -1, "skip": 0}
        data = {"choice": votes_options[choice.to_sym], "comment": comment_id, "channel": "opinion_component"}
        response = self.class.post(self.vote_route, body: data, headers: self.headers)
        if not [200, 201].include? response.code
          raise "vote could not be saved: #{response.parsed_response}"
        end
      end

      def get_next_comment
          response = self.class.get(self.comment_route, headers: self.headers)
          if response.code == 200
            body = JSON.parse response.body
            if body["content"] == ""
              return {"content"=>"You have voted on all comments. Thank you for the participation.", "status"=>nil, "rejection_reason"=>nil, "rejection_reason_text"=>""}
            end
          else
            raise "comment could not be retrieved"
          end
      end

      def create_user
        response = self.class.post(self.new_user_route, body: JSON.generate(self.new_user_data), headers: { 'Content-Type' => 'application/json' })
        if response.code == 400
          raise "user exists"
        end
        body = JSON.parse response.body
        @token = body["token"]
      end

      def authenticate
        response = self.class.post(self.login_route, body: JSON.generate(self.user_data), headers: { 'Content-Type' => 'application/json' })
        if response.code == 200
          body = JSON.parse response.body
          @token = body["token"]
        else
          raise "error"
        end
      end
    end
  end
end
