# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'csv'

module Export
  module Csv

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
        CSV.generate(options) do |generator|
          generator << exportable.labels
          exportable.data_rows(:csv) do |row|
            generator << row
          end
        end
      end

      # convert to ISO-8859-1 (configurable, though) for Excel which is...,
      # well, has some success-potential to handle UTF-8
      def convert(data)
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
