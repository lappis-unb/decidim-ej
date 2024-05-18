module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      def index
        @conversation = client_api.fetch_conversation
        @comment = client_api.fetch_next_comment
      end

      def vote
        @conversation = client_api.fetch_conversation
        client_api.post_vote(params[:choice], params[:comment_id])
        @comment = client_api.fetch_next_comment

        render partial: "decidim/ej/ej/component"
      end

      private

      def client_api
        @client_api ||= ClientApi.new(current_user, EjClient.find_by(component: params[:component_id]))
      end
    end
  end
end
