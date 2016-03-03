# encoding: utf-8

#  Copyright (c) 2012-2016, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::CondensedContact

  CONDENSABLE_ATTRIBUTES = [:address, :last_name, :company_name, :company?,
                            :zip_code, :town, :country]

  class << self

    def condense_list(list)
      condensed = []

      list.map.with_index do |base_contactable, base_index|
        next if condensed.include?(base_contactable)
        candidates = condense_candidates(base_contactable, list[(base_index + 1)..-1])
        condensed += candidates
        condensed_contactable = new(base_contactable, candidates) if candidates.any?
        condensed_contactable || base_contactable
      end.compact
    end

    def condensable?(base_contactable, contactable)
      CONDENSABLE_ATTRIBUTES.all? do |attribute|
        base_contactable.try(attribute) == contactable.try(attribute)
      end
    end

    private

    def condense_candidates(base_contactable, list)
      list.select { |contactable| condensable?(base_contactable, contactable) }
    end

  end

  attr_reader :base_contactable, :other_contactables

  delegate(:country_label, :ignored_country?, *CONDENSABLE_ATTRIBUTES, to: :base_contactable)

  def initialize(base_contactable, contactables = [])
    @base_contactable = base_contactable
    @other_contactables = []
    condense(contactables)
  end

  def condensed_contactables
    [base_contactable] + other_contactables
  end

  def full_name
    "#{condensed_contactables.map(&:first_name).to_sentence} #{base_contactable.last_name}"
  end

  def condensable?(contactable)
    self.class.condensable?(self, contactable)
  end

  def condense(candidates)
    Array.wrap(candidates).each do |candidate|
      if condensable?(candidate) && !condensed_contactables.include?(candidate)
        other_contactables << candidate
      end
    end
  end

  alias_method :<<, :condense

end
