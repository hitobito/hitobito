# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module AppleWallet
    class Config
      FILE_PATH = Rails.root.join("config", "apple_wallet.yml")
      KEYS = %w[
        pass_type_identifier team_identifier
        p12_certificate_path p12_password
        wwdr_certificate_path
        web_service_url
        contact_info
      ].freeze

      class << self
        def exist?
          config.present?
        end

        KEYS.each do |key|
          define_method(key) { config[key] }
        end

        private

        def config
          return @config if defined?(@config)
          @config = load.freeze
        end

        def load
          return nil unless File.exist?(FILE_PATH)
          YAML.safe_load_file(FILE_PATH)&.fetch("apple_wallet", nil)
        end
      end
    end
  end
end
