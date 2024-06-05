# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ej
    module HasCredentials
      extend ActiveSupport::Concern

      included do
        has_secure_password :ej_password, validations: false
      end
    end
  end
end
