# frozen_string_literal: true

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe I18nEnums do

  let(:person) { Person.new(first_name: 'Dummy') }

  it 'returns translated labels' do
    person.gender = 'm'
    expect(person.gender_label).to eq 'männlich'
    person.gender = 'w'
    expect(person.gender_label).to eq 'weiblich'
    person.gender = nil
    expect(person.gender_label).to eq 'unbekannt'
  end

  it 'returns translated label in french' do
    I18n.locale = :fr
    person.gender = 'm'
    expect(person.gender_label).to eq 'masculin'
    person.gender = 'w'
    expect(person.gender_label).to eq 'féminin'
    person.gender = ''
    expect(person.gender_label).to eq 'inconnu'
    I18n.locale = :de
  end

  it 'accepts only possible values' do
    person.gender = 'm'
    expect(person).to be_valid
    person.gender = ' '
    expect(person).to be_valid
    person.gender = nil
    expect(person).to be_valid
    person.gender = 'foo'
    expect(person).not_to be_valid
  end

  it 'has class side method to return all labels' do
    expect(Person.gender_labels).to eq(m: 'männlich', w: 'weiblich')
  end

  context 'with i18n_prefix override' do
    before do
      clazz = Class.new(Person) do
        attr_accessor :gender_identity
        i18n_enum :gender_identity, Person::GENDERS, i18n_prefix: 'foo.bar'
      end
      stub_const('Individual', clazz)
    end

    let(:individual) { Individual.new(first_name: 'Dummy') }

    around do |example|
      with_translations(
        de: { foo: { bar: { m: 'maskulin', w: 'feminin', _nil: 'undefiniert' } } },
        fr: { foo: { bar: { m: 'mâle', w: 'femelle', _nil: 'indéfini' } } }
      ) do
        example.call
      end
    end

    it 'returns translated labels' do
      individual.gender_identity = 'm'
      expect(individual.gender_identity_label).to eq 'maskulin'
      individual.gender_identity = 'w'
      expect(individual.gender_identity_label).to eq 'feminin'
      individual.gender_identity = nil
      expect(individual.gender_identity_label).to eq 'undefiniert'
    end

    it 'returns translated label in french' do
      I18n.locale = :fr
      individual.gender_identity = 'm'
      expect(individual.gender_identity_label).to eq 'mâle'
      individual.gender_identity = 'w'
      expect(individual.gender_identity_label).to eq 'femelle'
      individual.gender_identity = ''
      expect(individual.gender_identity_label).to eq 'indéfini'
    end

    it 'has class side method to return all labels' do
      expect(Individual.gender_identity_labels).to eq(m: 'maskulin', w: 'feminin')
    end
  end
end
