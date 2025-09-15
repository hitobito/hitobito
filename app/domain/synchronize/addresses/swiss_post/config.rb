# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Synchronize::Addresses::SwissPost
  class Config
    ENCODING = "Windows-1252"
    COL_SEP = "\t"
    ROW_SEP = "\r\n"
    LOG_CATEGORY = "cleanup"

    FILE_PATH = Rails.root.join("config", "post-address-sync.yml")
    KEYS = %w[host path username password query_key batch_key person_constraints role_types].freeze

    class << self
      def exist?
        config.present?
      end

      KEYS.each do |key|
        define_method(key) do
          config[key]
        end
      end

      private

      def config
        return @config if defined?(@config)

        @config = load.freeze
      end

      def load
        return nil unless File.exist?(FILE_PATH)

        key = FILE_PATH.basename(".*").to_s
        YAML.safe_load_file(FILE_PATH)&.fetch(key, nil)
      end
    end
  end
end
