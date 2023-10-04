# frozen_string_literal: true

module Decidim
  module Ej
    class EjClient < ApplicationRecord
      include Decidim::Resourceable
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::TranslatableResource

      translatable_fields :host

      component_manifest_name "ej_client"

      def self.log_presenter_class_for(_log)
        Decidim::Pages::AdminLog::PagePresenter
      end

      # Public: Pages do not have title so we assign the component one to it.
      def title
        component.name
      end
    end
  end
end
