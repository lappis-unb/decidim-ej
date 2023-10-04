# frozen_string_literal: true

module Decidim
  module Ej
    # This is the engine that runs on the public interface of `Ej`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Ej::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        post "/", to: "ej#update", as: :ej
        root to: "ej#index"
        resources :ej
      end

      def load_seed
        nil
      end
    end
  end
end
