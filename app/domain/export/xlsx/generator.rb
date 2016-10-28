# encoding: utf-8

#  Copyright (c) 2012-2016, insieme Schweiz. This file is part of
#  hitobito_insieme and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_insieme.
#

require 'axlsx'
module Export::Xlsx

  def self.export(exportable)
    Generator.new(exportable).xls
  end

  class Generator

    attr_reader :xlsx

    def initialize(exportable)
      @xlsx = generate(exportable)
    end

    private

    def generate(exportable)
      package = Axlsx::Package.new do |p|
        p.workbook do |wb|
          build_sheets(wb, exportable)
        end
      end
      package.to_stream.read
    end

    def build_sheets(wb, exportable)
      load_style_definitions(wb.styles, exportable)
      wb.add_worksheet do |sheet|
        add_header_rows(sheet, exportable)

        add_attribute_label_row(sheet, exportable)

        add_data_rows(sheet, exportable)
        apply_column_widths(sheet, exportable)
        sheet.page_setup.set(exportable.page_setup)
      end
    end

    def add_header_rows(sheet, exportable)
      exportable.header_rows.each do |r|
        sheet.add_row(r[:values], row_style(r))
      end
    end

    def add_attribute_label_row(sheet, exportable)
      sheet.add_row(exportable.labels, style_definition(:attribute_labels))
    end

    def add_data_rows(sheet, exportable)
      exportable.data_rows.each do |row|
        options = {}
        options.merge!(row_style(row))
        options.merge!(data_row_height(exportable.data_row_height))
        sheet.add_row(row[:values], options)
      end
    end

    def data_row_height(height)
      height.nil? ? {} : { height: height }
    end

    def apply_column_widths(sheet, exportable)
      sheet.column_widths(*exportable.column_widths)
    end

    def load_style_definitions(workbook_styles, exportable)
      definitions = exportable.style_definitions
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

    def row_style(row)
      style = row[:style]
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
      { style: styles }
    end

  end

end
