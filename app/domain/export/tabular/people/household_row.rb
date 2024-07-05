# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class HouseholdRow < PersonRow
    SHORTEN_AT = 40

    def entry
      household.first
    end

    def household
      # Make sure it is an array, in case someone passes in a plain non-household list
      Array.wrap(@entry)
    end

    def name
      if entry.company?
        entry.company_name
      else
        with_combined_first_names.collect do |last_name, combined_first_name|
          without_blanks([combined_first_name, last_name]).join(" ")
        end.join(", ")
      end
    end

    def salutation
      return nil unless entry.respond_to? :salutation # not nil, just w/o salutation

      Salutation.new(entry).value_for_household(household)
    end

    private

    def with_combined_first_names
      names_hash.transform_values do |first_names|
        first_names = without_blanks(first_names)
        first_names = only_initials(first_names) if length > SHORTEN_AT
        combine(first_names)
      end
    end

    def names_hash
      @names_hash ||= first_names.zip(last_names).each_with_object({}) do |(first, last), memo|
        last = first_present_last_name if last.blank?
        memo[last] ||= []
        memo[last] << first
      end
    end

    def combine(first_names)
      if first_names.count > 2
        last_first_name = first_names.pop
        [first_names.join(", "), last_first_name].to_sentence
      elsif first_names.count == 2
        first_names.to_sentence
      else
        first_names.first
      end
    end

    def first_present_last_name
      last_names.find(&:present?)
    end

    def first_names
      household.map { |person| person.first_name&.strip }
    end

    def last_names
      household.map { |person| person.last_name&.strip }
    end

    def without_blanks(array)
      array.compact_blank.compact
    end

    def only_initials(array)
      array.collect { |name| "#{name.first}." }
    end

    def length
      names_hash.keys.uniq.join.size + names_hash.values.join.size
    end
  end
end
