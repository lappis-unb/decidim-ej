module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      before_action :authenticate_user!

      # Links a already created EJ User (maybe created in WhatsApp or Telegram) to
      # the current_user.
      def link_external_user
        user_data = JWT.decode(params[:user_data], nil, false).first.with_indifferent_access

        if user_data[:exp] >= Time.current.to_i
          api_client.link_user_account(user_data[:secret_id], user_data[:user_id])
        else
          @error_message = "Este link que você utilizou já expirou. Solicite um novo link e tente novamente."
        end
      rescue Connector::Exceptions::UserCannotBeLinked
        @error_message = "Sua conta não pôde ser vinculada. Mas você ainda poderá participar das enquetes por aqui."
      end

      def home
        @conversation_id = current_component.settings[:conversation_id]
        set_conversation_info
      end

      def index
        @conversations = api_client.fetch_conversations

        @conversations.each do |conversation|
          response_user_stats = @api_client.fetch_user_stats(conversation["id"])
          conversation["user_stats"] = response_user_stats
        end

        @conversations
      end

      def show
        @conversation_id = params[:id]
        set_conversation_info
      end

      def user_comments
        @user_comments = api_client.fetch_user_comments
      end

      def user_votes
        index
      end

      def post_vote
        @conversation_id = params[:id]
        api_client.post_vote(params[:choice], params[:comment_id])
        set_conversation_info

        render partial: "decidim/ej/ej/component"
      end

      def post_comment
        @conversation_id = params[:id]
        api_client.post_comment(@conversation_id, params[:body])
        set_conversation_info

        flash[:notice] = "Seu comentário foi enviado para moderação. Caso seja aprovado, ficará disponível para votação na enquete."
        redirect_to ej_path(@conversation_id)
      end

      private

      def set_conversation_info
        @conversation = api_client.fetch_conversation(@conversation_id)
        @comment = api_client.fetch_next_comment(@conversation_id)
        @user_participation_ratio = @conversation[:user_stats][:participation_ratio].to_f * 100.0
      end

      def api_client
        @api_client ||= Decidim::Ej::Connector::Client.new(current_component.settings[:host], current_user)
      end
    end
  end
end
