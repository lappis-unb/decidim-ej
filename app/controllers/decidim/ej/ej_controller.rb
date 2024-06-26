module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      before_action :set_conversation
      before_action :set_comment, only: :index

      def index; end

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
