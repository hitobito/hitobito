# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Import
  class PersonDuplicateFinder
    include Translatable

    # if multiple rows match the same existing person, always return the same object
    attr_reader :unique_entries

    DUPLICATE_ATTRIBUTES = [
      :first_name,
      :last_name,
      :company_name,
      :zip_code,
      :birthday
    ]

    def initialize
      @unique_entries = []
    end

    # returns the first duplicate with errors if there are multiple
    def find(attrs)
      people_ids = duplicate_ids(attrs)
      if people_ids.present?
        person = ::Person.find(people_ids.first)
        if people_ids.size == 1
          unique_entries << person.id unless unique_entries.include?(person.id)
        else
          person.errors.add(:base, translate(:duplicates, count: people_ids.size))
        end
        person
      end
    end

    def unique_count
      unique_entries.size
    end

    private

    def duplicate_ids(attrs)
      conditions = duplicate_conditions(attrs)
      if conditions.first.present?
        ::Person.where(conditions).pluck(:id)
      else
        []
      end
    end

    #  leave this here for now to keep the API compatible
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
      existing_duplicate_attrs(attrs).each do |key, value|
        condition = conditions.first
        connector = condition.present? ? " AND " : ""
        comparison = if %w[first_name last_name company_name].include?(key.to_s)
          "#{key} = ?"
        else
          "(#{key} = ? OR #{key} IS NULL)"
        end
        conditions[0] = "#{condition}#{connector}#{comparison}"
        value = parse_date(value) if key.to_sym == :birthday
        conditions << value
      end
    end

    def append_email_condition(attrs, conditions)
      if attrs[:email].present?
        condition = conditions.first
        conditions[0] = if condition.present?
          "(#{condition}) OR email = ?"
        else
          "email = ?"
        end
        conditions << attrs[:email]
      end
    end

    def existing_duplicate_attrs(attrs)
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
