# frozen_string_literal: true

module Decidim
  module Ej
    class LinkExternalUser < Decidim::Command
      def initialize(jwt_token, current_user, api_client)
        @jwt_token = jwt_token
        @current_user = current_user
        @api_client = api_client

        extract_jwt_data
      end

      def call
        return broadcast(:invalid) unless user_data_valid?
        return broadcast(:user_taken) if user_already_linked?
        return broadcast(:token_taken) if token_already_linked?

        link_user_account ? broadcast(:ok) : broadcast(:error)
      end

      private

      attr_reader :jwt_token, :current_user, :api_client, :user_data

      def extract_jwt_data
        @user_data = JWT.decode(
          jwt_token,
          Rails.application.secrets.ej[:jwt_secret],
          true,
          { algorithm: 'HS256' }
        ).try(:first).try(:with_indifferent_access)
      rescue JWT::DecodeError, JWT::ExpiredSignature => e
        Rails.logger.error("Error while decoding JWT token. #{e}")
        @user_data = nil
      end

      def user_data_valid?
        return false unless user_data.is_a?(Hash)

        jwt_expected_keys.all? { |key| user_data.has_key?(key) && user_data[key].present? }
      end

      def jwt_expected_keys
        [:user_id, :secret_id, :exp].freeze
      end

      def user_already_linked?
        current_user.ej_external_identifier.present?
      end

      def token_already_linked?
        Decidim::User.find_by(ej_external_identifier: user_data[:user_id]).present?
      end

      def link_user_account
        api_client.link_user_account(user_data[:secret_id])

        current_user.ej_external_identifier = user_data[:user_id]
        current_user.generate_ej_password_with_external_id!(user_data[:user_id])
        current_user.has_ej_account = true
        current_user.save
      rescue Connector::Exceptions::RequestError
        false
      end
    end
  end
end