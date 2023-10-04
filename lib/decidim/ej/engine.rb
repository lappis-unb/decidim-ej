# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Ej
    # This is the engine that runs on the public interface of ej.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Ej

      routes do
        # Add engine routes here
        resources :ej
        root to: "ej#index"
      end

      initializer "Ej.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
