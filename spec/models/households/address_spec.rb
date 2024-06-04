# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Households::Address do

  let(:person) { Person.new }
  let(:household) { Household.new(person) }
  subject(:address) { described_class.new(household) }

  describe '#attrs' do
    it 'reads from reference person' do
      person.street = 'Superstreet'
      person.housenumber = 123
      person.zip_code = 4567
      person.town = 'Supertown'
      expect(address.attrs).to eq(
        address_care_of: nil,
        country: nil,
        housenumber: '123',
        postbox: nil,
        street: 'Superstreet',
        town: 'Supertown',
        zip_code: '4567'
      )
    end

    it 'ignores address from other person' do
      person.street = 'Superstreet'
      household.add(Person.new(street: 'Backstreet'))
      expect(address.attrs[:street]).to eq 'Superstreet'
    end

    it 'ignores address from first person if others before are black' do
      household.add(Person.new)
      household.add(Person.new(street: 'Backstreet'))
      expect(address.attrs[:street]).to eq 'Backstreet'
    end
  end

  describe '#dirty?' do
    it 'is false when people share same address' do
      person.street = 'Superstreet'
      household.add(Person.new(street: 'Superstreet'))
      expect(address).not_to be_dirty
    end

    it 'is true when people address differ' do
      person.street = 'Superstreet'
      household.add(Person.new(street: 'Backstreet'))
      expect(address).to be_dirty
    end

    it 'is true when people address is blank' do
      person.street = 'Superstreet'
      household.add(Person.new)
      expect(address).to be_dirty
    end
  end

  describe '#oneline' do
    it 'is blank when blank' do
      expect(address.oneline).to be_blank
    end

    it 'is present when present' do
      person.street = 'Superstreet'
      person.housenumber = 123
      person.zip_code = 4567
      person.town = 'Supertown'
      expect(address.oneline).to eq 'Superstreet 123, 4567 Supertown'
    end
  end

end
