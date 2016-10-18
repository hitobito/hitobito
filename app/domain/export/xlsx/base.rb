# encoding: utf-8

#  Copyright (c) 2012-2016, insieme Schweiz. This file is part of
#  hitobito_insieme and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_insieme.
#

module Export::Xlsx
  # The base class for all the different xlsx export files.
  class Base < ::Export::Base

    class_attribute :model_class, :row_class, :style_class
    self.row_class = Row
    self.style_class = Style

    class << self
      def export(*args)
        Export::Xlsx::Generator.new(new(*args)).xlsx
      end
    end

    def header_rows
      @header_rows ||= []
    end

    def data_rows
      rows = []
      list.each.with_index do |entry, index|
        rows << { values: values(entry), style: row_style(index) }
      end
      rows
    end

    def style_definitions
      style.style_definitions
    end

    private

    def add_header_row(values = [], style = :default)
      header_rows << { values: values, style: style }
    end

    def row_style(index)
      style.row_styles[index] || style.default_style_data_rows
    end

    def style
      @style ||= style_class.new
    end

  end
end
