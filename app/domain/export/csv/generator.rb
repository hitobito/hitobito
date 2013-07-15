require 'csv'
module Export

  module Csv

    def self.export(exportable)
      Generator.new(exportable).csv
    end

    class Generator
      attr_reader :csv

      def initialize(exportable)
        @csv = convert(generate(exportable))
      end

      private

      def generate(exportable)
        CSV.generate(options) { |generator| exportable.to_csv(generator) }
      end

      # convert to 8859 for excel which is too stupid to handle utf-8
      def convert(data)
        Settings.csv.encoding.present? ? Iconv.conv(Settings.csv.encoding, 'UTF-8', data) : data
      end

      def options
        { col_sep: Settings.csv.separator.strip, row_sep: "\r\n" }
      end
    end
  end
end
