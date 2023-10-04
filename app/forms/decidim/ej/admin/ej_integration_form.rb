# frozen_string_literal: true

module Decidim
  module Ej
    module Admin
      # This class holds a Form to update pages from Decidim's admin panel.
      class EjIntegrationForm < Decidim::Form
        include TranslatableAttributes
        translatable_attribute :host, String
        translatable_attribute :conversation_id, Integer
      end
    end
  end
end
