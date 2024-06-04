# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Households::Address

  delegate :reference_person, :people, to: :@household

  def initialize(household)
    @household = household
  end

  def attrs
    @attrs ||= find_address_person&.address_attrs || {}
  end

  def oneline
    [
      build_street_and_number,
      build_zip_code_and_town
    ].compact_blank.join(', ')
  end

  def dirty?
    !people.map(&:address_attrs).map(&:compact_blank).uniq.one?
  end

  private

  def find_address_person
    ([reference_person] + people).find do |person|
      person.address_attrs.compact_blank.present?
    end
  end

  def build_street_and_number
    if FeatureGate.enabled?('structured_addresses')
      [attrs[:street], attrs[:housenumber]].compact_blank.join(' ')
    else
      attrs[:address].to_s
    end
  end

  def build_zip_code_and_town
    [attrs[:zip_code], attrs[:town]].compact_blank.join(' ').squish
  end
end
