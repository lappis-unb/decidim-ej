module Decidim
  module Ej
    module Admin
      class EjController < Admin::ApplicationController

        def index
          []
        end

        def create
          debugger
          redirect_to :action => "new"
        end

        def edit
          ej_client = self.integration()
          @form = form(Admin::EjIntegrationForm).from_model(ej_client)
        end

        def integration
          EjClient.find(component: current_component)
        end
      end
    end
  end
end
