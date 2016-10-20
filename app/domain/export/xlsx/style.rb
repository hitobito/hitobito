# encoding: utf-8

#  Copyright (c) 2012-2016, insieme Schweiz. This file is part of
#  hitobito_insieme and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_insieme.
#

require 'axlsx'
module Export::Xlsx
  class Style
    LABEL_BACKGROUND = Settings.xlsx.label_background
    class_attribute :style_definition_labels
    # extend in subclass and add your own definitions
    self.style_definition_labels = [:default, :attribute_labels, :centered]

    def style_definitions
      style_definition_labels.each_with_object({}) do |l, d|
        d[l] = send("#{l}_style")
      end
    end

    # specify styles to apply per row or cell
    def row_styles
      []
    end

    # override in subclass to define column widths
    def column_widths
      []
    end

    def default_style_data_rows
      :centered
    end

    private

    def style_definition_labels
      self.class.style_definition_labels
    end

    # style definitions
    def default_style
      { style: {
        font_name: Settings.xlsx.font_name, alignment: { horizontal: :left } }
      }
    end

    def attribute_labels_style
      default_style.deep_merge(style: { bg_color: LABEL_BACKGROUND })
    end

    def centered_style
      default_style.deep_merge(style: { alignment: { horizontal: :center } })
    end
  end
end
