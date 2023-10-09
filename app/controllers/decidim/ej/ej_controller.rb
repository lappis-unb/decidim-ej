module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      def index
        ej_component = EjClient.find_by(component: params[:component_id])
        client_api = ClientApi.new(current_user, ej_component)
        begin
          client_api.create_user
        rescue
          client_api.authenticate
        end
        @conversation = client_api.get_conversation()
      end
    end
  end
end
