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
        post "vote", to: "ej#vote", as: :voting
        get "user_comments", to: "ej#user_comments", as: :user_comments

        root to: "ej#home"

        resources :ej, path: 'ej/surveys', only: [:index, :show] do
          member do
            post :post_comment
          end
        end
      end

      initializer "Ej.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
