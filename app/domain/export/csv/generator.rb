# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
