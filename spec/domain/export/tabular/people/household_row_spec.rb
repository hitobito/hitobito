# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
require 'spec_helper'

describe Export::Tabular::People::HouseholdRow do
  subject { described_class.new(person) }

  context 'for companies' do
    let(:person) do
      Person.new(first_name: 'Tom', last_name: 'Tester', company: true, company_name: 'ACME Corp.')
    end

    it 'shows the company name for companies' do
      expect(subject.name).to eq 'ACME Corp.'
    end
  end

  context 'for people without name' do
    let(:person) { Person.new }

    it 'handles nil first and last name' do
      expect(subject.name).to eq ''
    end
  end

  context 'for people with a name' do
    let(:person) do
      Person
        .new(first_name: 'Poe', last_name: 'Dameron', gender: 'm')
        .tap do |person|
          allow(person).to receive(:salutation).and_return(:lieber_vorname)
        end
    end

    it 'shows the name' do
      expect(subject.name).to eq 'Poe Dameron'
    end

    it 'shows the salutation of this person' do
      expect(subject.salutation).to eq 'Lieber Poe'
    end
  end

  describe 'for households' do
    def person(first_name, last_name)
      Fabricate(:person, first_name: first_name, last_name: last_name, household_key: SecureRandom.uuid)
    end

    it 'treats blank last name as first present lastname' do
      expect(described_class.new([person('Andreas', 'Mäder'), person('Mara', '')]).name)
        .to eq 'Andreas und Mara Mäder'

      expect(described_class.new([
                                     person('Andreas', 'Mäder'),
                                     person('Mara', ''),
                                     person('Blunsch', 'Wyss')
                                 ]).name)
        .to eq 'Andreas und Mara Mäder, Blunsch Wyss'

      expect(described_class.new([
                                     person('Andreas', 'Mäder'),
                                     person('Mara', ''),
                                     person('Rahel', 'Emmenegger'),
                                     person('Blunsch', '')
                                 ]).name)
        .to eq 'Andreas, Mara und Blunsch Mäder, Rahel Emmenegger'

      expect(described_class.new([person('Andreas', ''), person('Mara', '')]).name)
        .to eq 'Andreas und Mara'
    end

    it 'does not output anything if first and last names are blank' do
      expect(described_class.new([person('', '')]).name).to be_blank
      expect(described_class.new([person(nil, nil)]).name).to be_blank
    end

    it 'combines two people with same last_name' do
      expect(described_class.new([person('Andreas', 'Mäder'), person('Mara', 'Mäder')]).name)
          .to eq 'Andreas und Mara Mäder'
    end

    it 'combines multiple people with same last_name' do
      expect(described_class.new([
                                     person('Andreas', 'Mäder'),
                                     person('Mara', 'Mäder'),
                                     person('Ruedi', 'Mäder'),
                                 ]).name)
        .to eq 'Andreas, Mara und Ruedi Mäder'
    end

    it 'joins two different names by SEPARATOR' do
      expect(described_class.new([person('Andreas', 'Mäder'), person('Rahel', 'Steiner')]).name)
        .to eq 'Andreas Mäder, Rahel Steiner'
    end

    it 'reduces first names to initial if line is too long' do
      expect(described_class.new([
                                     person('Andreas', 'Mäder'),
                                     person('Rahel', 'Steiner'),
                                     person('Rahel', 'Emmenegger'),
                                     person('Blunsch', 'Wyss'),
                                 ]).name)
        .to eq 'A. Mäder, R. Steiner, R. Emmenegger, B. Wyss'
    end

    it 'shows household salution' do
      person1 = person('Andreas', 'Mäder')
      allow(person1).to receive(:salutation).and_return(:lieber_vorname)
      person2 = person('Mara', 'Mäder')
      allow(person2).to receive(:salutation).and_return(:lieber_vorname)
      expect(described_class.new([person1, person2]).salutation)
          .to eq('Liebe*r Andreas, liebe*r Mara')
    end
  end
end
