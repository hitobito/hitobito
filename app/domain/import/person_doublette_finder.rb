# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class PersonDoubletteFinder
    include Translatable

    attr_reader :attrs

    DOUBLETTE_ATTRIBUTES = [
      :first_name,
      :last_name,
      :zip_code,
      :birthday
    ]

    def initialize(attrs)
      @attrs = attrs
    end

    def find_and_update
      people = duplicates
      if people.present?
        people.first.tap do |person|
          if people.size == 1
            assign_blank_attrs(person)
          else
            person.errors.add(:base, translate(:duplicates, count: people.size))
          end
        end
      end
    end

    def assign_blank_attrs(person)
      blank_attrs = attrs.select { |key, _value| person.attributes[key].blank? }
      person.attributes = blank_attrs
    end

    def duplicate_conditions
      [''].tap do |conditions|
        append_doublette_conditions(conditions)
        append_email_condition(conditions)
      end
    end

    private

    def duplicates
      conditions = duplicate_conditions
      if conditions.first.present?
        ::Person.includes(:roles).references(:roles).where(conditions).to_a
      else
        []
      end
    end

    def append_doublette_conditions(conditions)
      exisiting_doublette_attrs.each do |key, value|
        conditions.first << ' AND ' if conditions.first.present?
        conditions.first << "#{key} = ?"
        value = parse_date(value) if key.to_sym == :birthday
        conditions << value
      end
    end

    def append_email_condition(conditions)
      if attrs[:email].present?
        if conditions.first.present?
          conditions[0] = "(#{conditions[0]}) OR "
        end
        conditions.first << 'email = ?'
        conditions << attrs[:email]
      end
    end

    def exisiting_doublette_attrs
      existing = attrs.select do |key, value|
        value.present? && DOUBLETTE_ATTRIBUTES.include?(key.to_sym)
      end
      existing.delete(:birthday) unless parse_date(existing[:birthday])
      existing
    end

    def parse_date(date_string)
      if date_string.present?
        begin
          Time.zone.parse(date_string).to_date
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
