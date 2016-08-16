# encoding: utf-8

#  Copyright (c) 2012-2016, insieme Schweiz. This file is part of
#  hitobito_insieme and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_insieme.
#

module Export
  # Base class for csv/xlsx export
  class GeneralBase

    attr_reader :list

    def initialize(list)
      @list = list
    end
    
    # The list of all attributes exported to the csv/xlsx.
    # overridde either this or #attribute_labels
    def attributes
      attribute_labels.keys
    end

    # A hash of all attributes mapped to their labels exported to the csv/xlsx.
    # overridde either this or #attributes
    def attribute_labels
      @attribute_labels ||= build_attribute_labels
    end

    # List of all lables.
    def labels
      attribute_labels.values
    end

    private

    def build_attribute_labels
      attributes.each_with_object({}) do |attr, labels|
        labels[attr] = attribute_label(attr)
      end
    end

    def attribute_label(attr)
      human_attribute(attr)
    end

    def human_attribute(attr)
      model_class.human_attribute_name(attr)
    end

    def values(entry)
      row = row_for(entry)
      attributes.collect { |attr| row.fetch(attr) }
    end

    def row_for(entry)
      row_class.new(entry)
    end
  end
end
