# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.


module Export::Csv
  # The base class for all the different csv export files.
  class Base

    class_attribute :model_class, :row_class
    self.row_class = Row

    attr_reader :list

    class << self
      def export(*args)
        Export::Csv::Generator.new(new(*args)).csv
      end
    end

    def initialize(list)
      @list = list
    end

    def to_csv(generator)
      generator << labels
      list.each do |entry|
        generator << values(entry)
      end
    end

    # The list of all attributes exported to the csv.
    # overridde either this or #attribute_labels
    def attributes
      attribute_labels.keys
    end

    # A hash of all attributes mapped to their labels exported to the csv.
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
      row = row_class.new(entry)
      attributes.collect { |attr| row.fetch(attr) }
    end

  end

end
