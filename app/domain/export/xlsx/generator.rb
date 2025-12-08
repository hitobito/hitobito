#  Copyright (c) 2012-2017, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require "axlsx"
Axlsx.escape_formulas = true

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
      build_package.to_stream.read
    end

    def build_package
      Axlsx::Package.new do |p|
        p.workbook do |wb|
          build_sheets(wb)
        end
      end
    end

    def build_sheets(wb)
      load_style_definitions(wb.styles)

      wb.add_worksheet(name: sheet_name) do |sheet|
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

    def add_attribute_label_row(sheet)
      sheet.add_row(exportable.labels, style_definition(:attribute_labels))
    end

    def add_data_rows(sheet)
      column_styles = exportable.attribute_styles
      exportable.data_rows(:xlsx).each_with_index do |row, index|
        options = {}
        options.merge!(data_row_style(index, column_styles))
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

    def add_auto_filter(sheet)
      return unless exportable.auto_filter
      range = "#{sheet.rows[exportable.header_rows.size].cells.first.r}:" \
              "#{sheet.rows.last.cells.last.r}"
      sheet.auto_filter = range
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

    def data_row_style(index, column_styles)
      styles = style.row_style(index)
      if styles == :default && column_styles.present?
        styles = Array.new(exportable.attributes.size) do |i|
          column_styles[i] || :default
        end
      end
      row_style(styles)
    end

    def row_style(styles)
      if styles.is_a?(Array)
        cell_styles(styles)
      else
        style_definition(styles)
      end
    end

    def cell_styles(styles)
      styles = styles.collect do |s|
        style_definition(s)[:style]
      end
      {style: styles}
    end

    # Limit the sheet name length to `Axlsx::WORKSHEET_MAX_NAME_LENGTH` characters.
    # See also:
    # MS Office requires that the name attribute be less than or equal to 31 characters in length
    # and follow the character limitations for sheet-name and sheet-name-special in Formulas
    # ("[ISO/IEC-29500-1] §18.17").
    # https://learn.microsoft.com/en-us/openspecs/office_standards/ms-oi29500/ebf12ea5-2bb4-4af5-ab26-563f22d3f895
    def sheet_name
      exportable.sheet_name&.first(Axlsx::WORKSHEET_MAX_NAME_LENGTH)
    end
  end
end
