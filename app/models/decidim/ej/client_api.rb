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
          "conversations": "/api/v1/conversations/"
        }
      end

      def login_route
        return "#{@host}#{@routes[:login]}"
      end

      def new_user_route
        return "#{@host}#{@routes[:users]}"
      end

      def conversation_route
        return "#{@host}#{@routes[:conversations]}#{@conversation_id}"
      end

      def comment_route(*args)
        return "#{@host}#{@routes[:conversations]}#{@conversation_id}/random-comment"
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

      def vote(option)
      end

    def get_next_comment
        response = self.class.get(self.comment_route, headers: self.headers)
        if response.code == 200
          return JSON.parse response.body
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

      private

    end
  end
end
