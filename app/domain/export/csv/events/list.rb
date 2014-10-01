# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::Events
  class List < Export::Csv::Base
    include Translatable

    MAX_DATES = 3

    self.model_class = Event::Course
    self.row_class = Export::Csv::Events::Row

    private

    def build_attribute_labels
      course_labels
          .merge(date_labels)
          .merge(prefixed_contactable_labels(:contact))
          .merge(prefixed_contactable_labels(:leader))
    end

    def course_labels
      labels = { group_names: translate(:group_names),
                 number: human_attribute(:number),
                 kind: Event::Kind.model_name.human,
                 description: human_attribute(:description),
                 state: human_attribute(:state),
                 location: human_attribute(:location) }

      labels.delete(:kind) unless Event::Course.attr_used?(:kind_id)
      labels
    end

    def date_labels
      MAX_DATES.times.each_with_object({}) do |i, hash|
        prefix = "Datum #{i + 1} "
        hash[:"date_#{i}_label"] = "#{prefix}#{Event::Date.human_attribute_name(:label)}"
        hash[:"date_#{i}_location"] = "#{prefix}#{Event::Date.human_attribute_name(:location)}"
        hash[:"date_#{i}_duration"] = "#{prefix}Zeitraum"
      end
    end

    def prefixed_contactable_labels(prefix)
      contactable_keys.each_with_object({}) do |key, hash|
        hash[:"#{prefix}_#{key}"] =
          "#{translated_prefix(prefix)} #{Person.human_attribute_name(key)}"
      end
    end

    def contactable_keys
      [:name, :address, :zip_code, :town, :email, :phone_numbers]
    end

    def translated_prefix(prefix)
      case prefix
      when :leader then Event::Role::Leader.model_name.human
      when :contact then human_attribute(:contact)
      else prefix
      end
    end
  end
end
