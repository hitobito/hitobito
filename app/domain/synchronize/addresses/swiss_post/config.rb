# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Synchronize::Addresses::SwissPost
  class Config
    COL_SEP = "\t"
    ROW_SEP = "\r\n"
    LOG_CATEGORY = "cleanup"

    FILE_PATH = Rails.root.join("config", "post-address-sync.yml")
    KEYS = %w[host path username password query_key batch_key
      person_constraints role_types excluded_tags].freeze

    BATCH_WITH_STATS = "eirene_maintenance_v2_L"

    STATS_FILES = {
      stats_file_de: "{###STATISTICFILE_DE###}",
      stats_file_fr: "{###STATISTICFILE_FR###}",
      stats_file_it: "{###STATISTICFILE_IT###}",
      stats_file_en: "{###STATISTICFILE_EN###}",
      stats_file_xml: "{###STATISTICFILE_XML###}"
    }

    class_attribute :encoding, default: "UTF-8"

    class << self
      def exist?
        config.present?
      end

      KEYS.each do |key|
        define_method(key) do
          config[key]
        end
      end

      def with_stats? = batch_key.downcase == BATCH_WITH_STATS.downcase

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
