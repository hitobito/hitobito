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
        certificate_path key_path key_password
        wwdr_certificate_path
        web_service_url
      ].freeze

      class << self
        def exist?
          config.present?
        end

        KEYS.each do |key|
          define_method(key) { config[key] }
        end

        # Load and return the PassKit certificate
        def certificate
          @certificate ||= OpenSSL::X509::Certificate.new(File.read(certificate_path))
        rescue => e
          raise "Failed to load PassKit certificate from #{certificate_path}: #{e.message}"
        end

        # Load and return the private key
        def key
          @key ||= begin
            password = key_password.presence
            OpenSSL::PKey::RSA.new(File.read(key_path), password)
          end
        rescue => e
          raise "Failed to load private key from #{key_path}: #{e.message}"
        end

        # Load and return the WWDR certificate
        def wwdr_certificate
          @wwdr_certificate ||= OpenSSL::X509::Certificate.new(File.binread(wwdr_certificate_path))
        rescue => e
          raise "Failed to load WWDR certificate from #{wwdr_certificate_path}: #{e.message}"
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
