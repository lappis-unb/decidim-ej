# frozen_string_literal: true

module Decidim
  module Ej
    class EjClient < ApplicationRecord
      include Decidim::HasComponent

      def self.log_presenter_class_for(_log)
        Decidim::Pages::AdminLog::PagePresenter
      end

      # Public: Pages do not have title so we assign the component one to it.
      def title
        component.name
      end

      def self.create(component_instance)
        @client = EjClient.new(
          component: component_instance,
          host: component_instance.settings.host,
          conversation_id: component_instance.settings.conversation_id
        )

        @client.save!
      end
    end
  end
end
