# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Import
  class PersonDuplicateFinder
    include Translatable

    # if multiple rows match the same existing person, always return the same object
    attr_reader :duplicate_entries

    DUPLICATE_ATTRIBUTES = [
      :first_name,
      :last_name,
      :company_name,
      :zip_code,
      :birthday
    ]

    def initialize
      @duplicate_entries = {}
    end

    def find(attrs)
      people = duplicates(attrs)
      if people.present?
        person = people.first
        if people.size == 1
          duplicate_entries[person.id] ||= person
        else
          person.errors.add(:base, translate(:duplicates, count: people.size))
          person
        end
      end
    end

    def duplicate_count
      duplicate_entries.size
    end

    private

    def duplicates(attrs)
      conditions = duplicate_conditions(attrs)
      if conditions.first.present?
        ::Person.where(conditions).to_a
      else
        []
      end
    end

    def duplicate_conditions(attrs)
      [""].tap do |conditions|
        append_duplicate_conditions(attrs, conditions)
        append_email_condition(attrs, conditions)
      end
    end

    def append_duplicate_conditions(attrs, conditions)
      exisiting_duplicate_attrs(attrs).each do |key, value|
        conditions.first << " AND " if conditions.first.present?
        conditions.first << if %w(first_name last_name company_name).include?(key.to_s)
          "#{key} = ?"
                            else
                              "(#{key} = ? OR #{key} IS NULL)"
                            end
        value = parse_date(value) if key.to_sym == :birthday
        conditions << value
      end
    end

    def append_email_condition(attrs, conditions)
      if attrs[:email].present?
        if conditions.first.present?
          conditions[0] = "(#{conditions[0]}) OR "
        end
        conditions.first << "email = ?"
        conditions << attrs[:email]
      end
    end

    def exisiting_duplicate_attrs(attrs)
      existing = attrs.select do |key, value|
        value.present? && DUPLICATE_ATTRIBUTES.include?(key.to_sym)
      end
      existing.delete(:birthday) unless parse_date(existing[:birthday])
      existing
    end

    def parse_date(date_string)
      if date_string.present?
        begin
          ActiveRecord::Type::Date.new.cast(date_string)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
