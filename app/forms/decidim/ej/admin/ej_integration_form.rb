# frozen_string_literal: true

module Decidim
  module Ej
    module Admin
      # This class holds a Form to update pages from Decidim's admin panel.
      class EjIntegrationForm < Decidim::Form
        attribute :host, String
        attribute :conversation_id, Integer
      end
    end
  end
end
