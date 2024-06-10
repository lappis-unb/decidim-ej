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

          current_component.settings = { host: form.host, conversation_id: form.conversation_id }.with_indifferent_access
          current_component.save!

          EjClient.find_by(component: current_component).update(host: form.host, conversation_id: form.conversation_id)

          flash[:notice] = :ok
          redirect_to ej_index_url
        end

        def edit
          ej_client = self.integration()
          @form = form(Admin::EjIntegrationForm).from_model(ej_client)
        end
      end
    end
  end
end
