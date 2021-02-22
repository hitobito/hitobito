#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Export::Tabular
  # Decorator for a row entry.
  # Attribute values may be accessed with fetch(attr).
  # If a method named #attr is defined on the decorator class, return its value.
  # Otherwise, the attr is delegated to the entry.
  class Row
    # regexp for attribute names which are handled dynamically.
    class_attribute :dynamic_attributes
    self.dynamic_attributes = {}

    attr_reader :entry, :format

    def initialize(entry, format = nil)
      @entry = entry
      @format = format
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
        if attr.to_s&.match?(regexp)
          return send(handler, attr)
        end
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def normalize(value)
      if value == true
        I18n.t("global.yes")
      elsif value == false
        I18n.t("global.no")
      elsif value.is_a?(Time)
        format == :xlsx ? value.to_s : "#{I18n.l(value.to_date)} #{I18n.l(value, format: :time)}"
      elsif value.is_a?(Date)
        format == :xlsx ? value.to_s : I18n.l(value)
      else
        value
      end
    end
  end
end
