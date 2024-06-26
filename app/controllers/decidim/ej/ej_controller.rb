module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      before_action :set_conversation, only: [:vote, :post_comment]
      before_action :set_comment, only: :index

      def index
        @conversations = client_api.fetch_conversations
      end

      def show
        client_api = ClientApi.new(current_user, OpenStruct.new(host: current_component.settings[:host], conversation_id: params[:id]))
        @conversation = client_api.fetch_conversation
        @comment = client_api.fetch_next_comment
      end

      def user_comments
        @user_comments = client_api.fetch_user_comments
      end

      def vote
        client_api.post_vote(params[:choice], params[:comment_id])

        @comment = client_api.fetch_next_comment

        render partial: "decidim/ej/ej/component"
      end

      def post_comment
        client_api.post_comment(params[:body])

        flash[:notice] = "Seu comentário foi enviado para moderação. Caso seja aprovado, ficará disponível para votação na enquete."
        redirect_to ej_index_url
      end

      private

      def set_conversation
        @conversation = client_api.fetch_conversation
      end

      def set_comment
        @comment ||= client_api.fetch_next_comment
      end

      def client_api
        @client_api ||= ClientApi.new(current_user, EjClient.find_by(component: params[:component_id]))
      end
    end
  end
end
