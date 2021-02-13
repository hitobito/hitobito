# encoding: utf-8

#  Copyright (c) 2012-2017, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require "axlsx"

module Export::Xlsx
  def self.export(exportable)
    Generator.new(exportable).call
  end

  class Generator
    attr_reader :exportable, :style

    def initialize(exportable)
      @exportable = exportable
      @style = Style.for(exportable.class)
    end

    def call
      generate
    end

    private

    def generate
      package = Axlsx::Package.new do |p|
        p.workbook do |wb|
          build_sheets(wb)
        end
      end
      package.to_stream.read
    end

    def build_sheets(wb)
      load_style_definitions(wb.styles)
      wb.add_worksheet do |sheet|
        add_header_rows(sheet)
        add_attribute_label_row(sheet)
        add_data_rows(sheet)
        apply_column_widths(sheet)

        sheet.page_setup.set(style.page_setup)
        add_auto_filter(sheet)
      end
    end

    def add_header_rows(sheet)
      exportable.header_rows.each_with_index do |row, index|
        sheet.add_row(row, row_style(style.header_style(index)))
      end
    end

    def add_auto_filter(sheet)
      return unless exportable.auto_filter
      range = "#{sheet.rows[exportable.header_rows.size].cells.first.r}:" \
              "#{sheet.rows.last.cells.last.r}"
      sheet.auto_filter = range
    end

    def add_attribute_label_row(sheet)
      sheet.add_row(exportable.labels, style_definition(:attribute_labels))
    end

    def add_data_rows(sheet)
      exportable.data_rows(:xlsx).each_with_index do |row, index|
        options = {}
        options.merge!(row_style(style.row_style(index)))
        options.merge!(data_row_height(style.data_row_height))
        sheet.add_row(row, options)
      end
    end

    def data_row_height(height)
      height.nil? ? {} : {height: height}
    end

    def apply_column_widths(sheet)
      sheet.column_widths(*style.column_widths)
    end

    def load_style_definitions(workbook_styles)
      definitions = style.style_definitions
      definitions.each do |k, v|
        # pass each style definition through add_style
        # as recommended by axlsx
        definitions[k][:style] = workbook_styles.add_style(v[:style])
      end
      @style_definitions = definitions
    end

    def style_definition(key)
      @style_definitions[key].deep_dup
    end

    def row_style(style)
      if style.is_a?(Array)
        cell_styles(style)
      else
        style_definition(style)
      end
    end

    def cell_styles(styles)
      styles = styles.collect do |s|
        style_definition(s)[:style]
      end
      {style: styles}
    end
  end
end
