# frozen_string_literal: true

module Decidim::Ej::Connector
  module Endpoints
    def login_path
      '/api/v1/login/'
    end

    def sign_up_path
      '/api/v1/users/'
    end

    def update_account_path(secret_id)
      "/api/v1/users/#{secret_id}/"
    end

    def conversations_path(conversation_id = nil)
      "/api/v1/conversations/#{conversation_id}"
    end

    def user_statistics_path(conversation_id)
      "/api/v1/conversations/#{conversation_id}/user-statistics/"
    end

    def random_comment_path(conversation_id)
      "/api/v1/conversations/#{conversation_id}/random-comment"
    end

    def votes_path
      '/api/v1/votes/'
    end

    def comments_path
      '/api/v1/comments/'
    end
  end
end