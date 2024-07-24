module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      before_action :authenticate_user!

      # Links a already created EJ User (maybe created in WhatsApp or Telegram) to
      # the current_user.
      def link_external_user
        Decidim::Ej::LinkExternalUser.call(params[:user_data] || params[:token], current_user, api_client) do
          on(:invalid) do
            flash[:alert] = "Link inválido ou expirado. Solicite um novo link e tente novamente."
          end

          on(:user_taken) do
            # TODO: melhorar a mensagem de erro e adiciona um fluxo pro usuário relatar problema clicando em algum
            # botão. Ao clicar no botão, devemos salvar no banco um "chamado" com os dados desse usuario para analisar
            flash[:alert] = "Sua conta já está vinculada a um número."
          end

          on(:token_taken) do
            # TODO: melhorar a mensagem de erro e adiciona um fluxo pro usuário relatar problema clicando em algum
            # botão. Ao clicar no botão, devemos salvar no banco um "chamado" com os dados desse usuario para analisar
            flash[:alert] = "Este link já foi utilizado por alguém, ou a conta que você deseja vincular já foi vinculada a outra pessoa."
          end

          on(:error) do
            # TODO: melhorar a mensagem de erro e salvar em algum lugar que esse erro aconteceu com o usuário.
            # De tal forma que seja possível identificar quais e quantos usuários estão com problemas na linkagem
            # de conta
            flash[:alert] = "Ocorreu um erro interno. O suporte técnico já está ciente e tentará resolver o mais rápido possível."
          end

          on(:ok) do
            flash[:alert] = nil
          end
        end
      end

      def unlink_user
        current_user.ej_password = nil
        current_user.has_ej_account = false
        current_user.ej_external_identifier = nil
        current_user.save!

        render json: { success: true, message: 'User unlinked!' }
      end

      def home
        @conversation_id = current_component.settings[:conversation_id]
        set_conversation_info
      end

      def index
        @selected_tab_index = params[:selected_tab_index] || "0"

        @conversations = api_client.fetch_conversations
        @user_comments = api_client.fetch_user_comments

        @comments_status_map = {
          approved: "Aprovado",
          rejected: "Rejeitado",
          pending: "Aguardando moderação"
        }

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
