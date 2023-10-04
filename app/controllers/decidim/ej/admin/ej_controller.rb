module Decidim
  module Ej
    module Admin
      class EjController < Admin::ApplicationController
        def index
          ej_client = EjClient.find_by(component: current_component)
          @form = form(EjIntegrationForm).from_model(ej_client)
        end

        def update
          form = form(EjIntegrationForm).from_params(params)
          host = form.host["en"]
          conversation_id = form.conversation_id["en"]
          component = Decidim::Component.find(params[:component_id])
          EjClient.find_by(component: component).update(host: host, conversation_id: conversation_id)
        end

        def edit
          ej_client = self.integration()
          @form = form(Admin::EjIntegrationForm).from_model(ej_client)
        end
      end
    end
  end
end
