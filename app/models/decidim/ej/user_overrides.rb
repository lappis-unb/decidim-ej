# frozen_string_literal: true

require 'active_support/concern'

module Decidim
  module Ej
    module UserOverrides
      extend ActiveSupport::Concern

      included do
        def ej_password=(value)
          self.encrypted_ej_password = AttributeEncryptor.encrypt(value)
        end

        def ej_password
          return AttributeEncryptor.decrypt(encrypted_ej_password) if encrypted_ej_password
        end

        def generate_random_ej_password!
          self.ej_password = SecureRandom.hex(12)

          # TODO: remove this update from here
          update(encrypted_ej_password: encrypted_ej_password)
        end

        def generate_ej_password_with_external_id!(external_id)
          # self.ej_password = Digest::SHA256.hexdigest(
          #   Base64.encode64("#{external_id}#{Rails.application.secrets.ej[:secret_key]}")
          # )
          self.ej_password = external_id
        end
      end
    end
  end
end
