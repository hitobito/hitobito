# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'csv-safe'

module Export
  module Csv

    UTF8_BOM = "\xEF\xBB\xBF"

    def self.export(exportable)
      Generator.new(exportable).call
    end

    class Generator
      attr_reader :exportable

      def initialize(exportable)
        @exportable = exportable
      end

      # Generate CSV and convert it to a configurable encoding. By default, it
      # is converted to ISO-8859-1. If the default-configuration is removed,
      # the data is not converted and output as UTF-8.
      def call
        convert(generate)
      end

      private

      def generate
        CSVSafe.generate(**options) do |generator|
          generator << exportable.labels
          exportable.data_rows(:csv) do |row|
            generator << row
          end
        end
      end

      # Allow different encodings (e.g. ISO-8859-1), configurable in the settings file.
      # Using the BOM header helps M$ excel to recognize utf8 files.
      def convert(data)
        if Settings.csv.utf8_bom.present?
          data = UTF8_BOM + data
        end
        if Settings.csv.encoding.present?
          data.encode(Settings.csv.encoding, undef: :replace, invalid: :replace)
        else
          data
        end
      end

      def options
        { col_sep: Settings.csv.separator.strip }
      end

    end
  end
end
