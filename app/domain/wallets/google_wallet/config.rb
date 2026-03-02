#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module GoogleWallet
    # Loads Google Wallet configuration from two files:
    #
    # config/google_wallet.yml
    #   google_wallet:
    #     issuer_id: "3388000000022266745"      # Issuer ID from Google Pay & Wallet Console
    #     issuer_email: "wallet-service@project.iam.gserviceaccount.com"  # Service account email
    #
    # config/google_service_account.json
    #   Service account credentials downloaded from Google Cloud Console:
    #   https://console.cloud.google.com/iam-admin/serviceaccounts
    #   The file must contain at least "private_key" and "client_email".
    #
    # exist? returns true only when both files are present.
    class Config
      FILE_PATH = Rails.root.join("config", "google_wallet.yml")
      SERVICE_ACCOUNT_PATH = Rails.root.join("config", "google_service_account.json")

      class << self
        def exist?
          issuer_id.present? && service_account_json.present?
        end

        def issuer_id = config&.fetch("issuer_id", nil)

        def issuer_email = config&.fetch("issuer_email", nil)

        def private_key
          @private_key ||= parsed_credentials["private_key"]
        end

        def client_email
          @client_email ||= parsed_credentials["client_email"]
        end

        def service_account_json
          return @service_account_json if defined?(@service_account_json)
          @service_account_json = load_service_account
        end

        private

        def config
          return @config if defined?(@config)
          @config = load_config
        end

        def load_config
          return nil unless File.exist?(FILE_PATH)
          YAML.safe_load_file(FILE_PATH)&.fetch("google_wallet", nil)&.freeze
        end

        def load_service_account
          return nil unless File.exist?(SERVICE_ACCOUNT_PATH)
          File.read(SERVICE_ACCOUNT_PATH)
        end

        def parsed_credentials
          @parsed_credentials ||= JSON.parse(service_account_json)
        end
      end
    end
  end
end
