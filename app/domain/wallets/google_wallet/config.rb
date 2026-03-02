#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module GoogleWallet
    class Config
      FILE_PATH = Rails.root.join("config", "google_wallet.yml")
      SERVICE_ACCOUNT_PATH = Rails.root.join("config", "google_service_account.json")
      KEYS = %w[issuer_id issuer_email].freeze

      class << self
        def exist?
          config.present?
        end

        KEYS.each do |key|
          define_method(key) { config[key] }
        end

        def service_account_json
          @service_account_json ||= File.read(SERVICE_ACCOUNT_PATH)
        end

        def private_key
          @private_key ||= parsed_credentials["private_key"]
        end

        def client_email
          @client_email ||= parsed_credentials["client_email"]
        end

        private

        def config
          return @config if defined?(@config)
          @config = load.freeze
        end

        def load
          return nil unless File.exist?(FILE_PATH)
          YAML.safe_load_file(FILE_PATH)&.fetch("google_wallet", nil)
        end

        def parsed_credentials
          @parsed_credentials ||= JSON.parse(service_account_json)
        end
      end
    end
  end
end
