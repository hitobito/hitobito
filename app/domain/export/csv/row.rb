# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Export::Csv

  # Decorator for a row entry.
  # Attribute values may be accessed with fetch(attr).
  # If a method named #attr is defined on the decorator class, return its value.
  # Otherwise, the attr is delegated to the entry.
  class Row

    # regexp for attribute names which are handled dynamically.
    class_attribute :dynamic_attributes
    self.dynamic_attributes = {}

    attr_reader :entry

    def initialize(entry)
      @entry = entry
    end

    def fetch(attr)
      normalize(value_for(attr))
    end

    private

    def value_for(attr)
      if dynamic_attribute?(attr.to_s)
        handle_dynamic_attribute(attr)
      elsif respond_to?(attr, true)
        send(attr)
      else
        entry.send(attr)
      end
    end

    def dynamic_attribute?(attr)
      dynamic_attributes.any? { |regexp, _| attr =~ regexp }
    end

    def handle_dynamic_attribute(attr)
      dynamic_attributes.each do |regexp, handler|
        if attr.to_s =~ regexp
          return send(handler, attr)
        end
      end
    end

    def normalize(value)
      if value == true
        I18n.t('global.yes')
      elsif value == false
        I18n.t('global.no')
      else
        value
      end
    end

  end
end
