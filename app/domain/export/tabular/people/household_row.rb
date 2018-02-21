# encoding: utf-8
#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class HouseholdRow < PersonRow

    SHORTEN_AT = 40

    def name
      with_combined_first_names.collect do |last_name, combined_first_name|
        without_blanks([combined_first_name, last_name]).join(' ')
      end.join(', ')
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
      @names_hash ||= first_names.zip(last_names).inject({}) do |memo, (first, last)|
        last = first_present_last_name if last.blank?
        memo[last] ||= []
        memo[last] << first
        memo
      end
    end

    def combine(first_names)
      if first_names.count > 2
        last_first_name = first_names.pop
        [first_names.join(', '), last_first_name].to_sentence
      elsif first_names.count == 2
        first_names.to_sentence
      else
        first_names.first
      end
    end

    def first_present_last_name
      last_names.select(&:present?).first
    end

    def first_names
      strip(entry.first_name.to_s.split(','))
    end

    def last_names
      strip(entry.last_name.to_s.split(','))
    end

    def strip(array)
      array.collect { |string| string.strip }
    end

    def without_blanks(array)
      array.reject(&:blank?).compact
    end

    def only_initials(array)
      array.collect { |name| "#{name.first}." }
    end

    def length
      names_hash.keys.uniq.join.size + names_hash.values.join.size
    end

  end
end
