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
        get "user_comments", to: "ej#user_comments", as: :user_comments
        get "user_votes", to: "ej#user_votes", as: :user_votes

        get 'link_external_user', controller: 'ej'
        get 'unlink_user', controller: 'ej'

        root to: "ej#home"

        resources :ej, path: 'ej/surveys', only: [:index, :show] do
          member do
            post :post_comment
            post :post_vote
          end
        end
      end

      config.to_prepare do
        Decidim::User.include(UserOverrides)
      end

      initializer "Ej.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
