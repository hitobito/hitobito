#  Copyright (c) 2012-2016, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require "axlsx"

module Export::Xlsx
  class Style
    class << self
      def register(style_class, *exportables)
        exportables.each do |e|
          registry[e] = style_class
        end
      end

      def for(exportable)
        registry.fetch(exportable, self).new
      end

      private

      def registry
        @registry ||= {}
      end
    end

    A4 = 9
    LABEL_BACKGROUND = Settings.xlsx.label_background

    # These formats are using localization in Excel to format dates and numbers in the given locale
    # https://github.com/randym/axlsx/blob/master/lib/axlsx/stylesheet/num_fmt.rb
    NUM_FORMATS = {
      decimal: 2, # '0.00'
      currency: 2, # '0.00'
      date: 14, # 'dd.mm.yyyy'
      time: 20, # 'HH:MM'
      datetime: 22 # 'dd.mm.yyyy HH:MM'
    }

    class_attribute :style_definition_labels, :data_row_height

    # extend in subclass and add your own definitions
    self.style_definition_labels = [:default, :attribute_labels, :centered] + NUM_FORMATS.keys

    def style_definitions
      style_definition_labels.each_with_object({}) do |l, d|
        d[l] = send(:"#{l}_style")
      end
    end

    def data_row_height
      self.class.data_row_height
    end

    def header_style(index)
      header_styles[index] || :default
    end

    def row_style(index)
      row_styles[index] || default_style_data_rows
    end

    # specify styles to apply per header row or cell
    def header_styles
      []
    end

    # specify styles to apply per data row or cell
    def row_styles
      []
    end

    # override in subclass to define column widths
    def column_widths
      []
    end

    # override in subclass to define page setup
    def page_setup
      {paper_size: A4,
       fit_to_height: 1,
       orientation: :landscape}
    end

    def default_style_data_rows
      :default
    end

    private

    def style_definition_labels
      self.class.style_definition_labels
    end

    # style definitions
    def default_style
      {
        style: {
          font_name: Settings.xlsx.font_name, alignment: {horizontal: :left}
        }
      }
    end

    def attribute_labels_style
      default_style.deep_merge(style: {bg_color: LABEL_BACKGROUND})
    end

    def centered_style
      default_style.deep_merge(style: {alignment: {horizontal: :center}})
    end

    NUM_FORMATS.each do |key, fmt|
      define_method(:"#{key}_style") do
        default_style.deep_merge(style: {num_fmt: fmt})
      end
    end
  end
end
