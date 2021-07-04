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
    def household(first_names = [], last_names = [])
      person = Person.new(
        first_name: first_names.join(','),
        last_name: last_names.join(','),
        household_key: SecureRandom.uuid
      ).tap do |p|
        allow(p).to receive(:salutation).and_return('lieber_vorname')
      end

      described_class.new(person)
    end

    it 'treats blank last name as first present lastname' do
      expect(household(%w(Andreas Mara), ['Mäder', '']).name)
        .to eq 'Andreas und Mara Mäder'

      expect(household(%w(Andreas Mara Blunsch), ['Mäder', '', 'Wyss']).name)
        .to eq 'Andreas und Mara Mäder, Blunsch Wyss'

      expect(household(%w(Andreas Mara Rahel Blunsch), ['Mäder', '', 'Emmenegger', '']).name)
        .to eq 'Andreas, Mara und Blunsch Mäder, Rahel Emmenegger'

      expect(household(%w(Andreas Mara), ['', '']).name)
        .to eq 'Andreas und Mara'
    end

    it 'does not output anything if first and last names are blank' do
      expect(household([''], ['']).name).to be_blank
      expect(household([nil, nil], [nil]).name).to be_blank
    end

    it 'combines two people with same last_name' do
      expect(household(%w(Andreas Mara), %w(Mäder Mäder)).name).to eq 'Andreas und Mara Mäder'
    end

    it 'combines multiple people with same last_name' do
      expect(household(%w(Andreas Mara Ruedi), %w(Mäder Mäder Mäder)).name)
        .to eq 'Andreas, Mara und Ruedi Mäder'
    end

    it 'joins two different names by SEPARATOR' do
      expect(household(%w(Andreas Rahel), %w(Mäder Steiner)).name)
        .to eq 'Andreas Mäder, Rahel Steiner'
    end

    it 'reduces first names to initial if line is too long' do
      expect(household(
        %w(Andreas Rahel Rahel Blunsch),
        %w(Mäder Steiner Emmenegger Wyss)
      ).name)
        .to eq 'A. Mäder, R. Steiner, R. Emmenegger, B. Wyss'
    end

    it 'shows no salution' do
      expect(household(%w(Andreas Rahel), %w(Mäder Steiner)).salutation).to be_nil
    end
  end
end
