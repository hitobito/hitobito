# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::Events
  class List < Export::Csv::Base
    include Translatable

    MAX_DATES = 3

    self.row_class = Export::Csv::Events::Row

    private

    def build_attribute_labels
      {}.tap do |labels|
        add_main_labels(labels)
        add_date_labels(labels)
        add_prefixed_contactable_labels(labels, :contact)
        add_prefixed_contactable_labels(labels, :leader)
        add_additional_labels(labels)
      end
    end

    def add_main_labels(labels)
      add_used_attribute_label(labels, :name)
      labels[:group_names] = translate(:group_names)
      add_used_attribute_label(labels, :number)
      labels[:kind] = Event::Kind.model_name.human if attr_used?(:kind_id)
      add_used_attribute_label(labels, :description)
      add_used_attribute_label(labels, :state)
      add_used_attribute_label(labels, :location)
    end

    def add_additional_labels(labels)
      add_used_attribute_label(labels, :motto)
      add_used_attribute_label(labels, :cost)
      add_used_attribute_label(labels, :application_opening_at)
      add_used_attribute_label(labels, :application_closing_at)
      add_used_attribute_label(labels, :maximum_participants)
      add_used_attribute_label(labels, :external_applications)
      add_used_attribute_label(labels, :priorization)
      labels[:teamer_count] = human_attribute(:teamer_count)
      labels[:participant_count] = human_attribute(:participant_count)
      labels[:applicant_count] = human_attribute(:applicant_count)
    end

    def add_date_labels(labels)
      MAX_DATES.times.each do |i|
        prefix = "Datum #{i + 1} "
        labels[:"date_#{i}_label"] = "#{prefix}#{Event::Date.human_attribute_name(:label)}"
        labels[:"date_#{i}_location"] = "#{prefix}#{Event::Date.human_attribute_name(:location)}"
        labels[:"date_#{i}_duration"] = "#{prefix}Zeitraum"
      end
    end

    def add_used_attribute_label(labels, attr)
      if attr_used?(attr)
        labels[attr] = human_attribute(attr)
      end
    end

    def attr_used?(attr)
      model_class.attr_used?(attr)
    end

    def add_prefixed_contactable_labels(labels, prefix)
      contactable_keys.each do |key|
        labels[:"#{prefix}_#{key}"] =
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

    def model_class
      @model_class ||= list.first ? list.first.class : Event::Course
    end
  end
end
