# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::Housemate do
  subject(:mate) { described_class.new }

  describe 'attribute assignments' do
    it 'works via constructor for strings' do
      expect(described_class.new('first_name' => 'test').first_name).to eq 'test'
    end

    it 'works via constructor for symbols' do
      expect(described_class.new(first_name: 'test').first_name).to eq 'test'
    end
  end

  describe 'validations' do
    it 'validates 5 fields' do
      expect(mate).not_to be_valid
      expect(mate.errors).to have(5).items
    end

    it 'validates first_name' do
      mate.required_attrs = [:first_name]
      expect(mate).not_to be_valid
      mate.first_name = 'test'
      expect(mate).to be_valid
    end

    it 'validates email for syntax' do
      mate.required_attrs = [:email]
      mate.email = 'test'
      expect(mate).not_to be_valid
      mate.email = 'test@example.com'
      expect(mate).to be_valid
    end

    it 'validates email for existing' do
      Fabricate(:person, email: 'test@example.com')
      mate.required_attrs = [:email]
      expect(mate).not_to be_valid
      mate.email = 'other@example.com'
      expect(mate).to be_valid
    end

    it 'validates email only occurs once in household' do
      mate.required_attrs = [:email]
      mate.household_emails = %w(test@example.com)
      mate.email = 'test@example.com'
      expect(mate).to be_valid

      mate.household_emails = %w(test@example.com test@example.com)
      expect(mate).not_to be_valid
    end

    describe 'person validations' do
      TestPerson = Class.new(described_class) do # rubocop:disable Lint/ConstantDefinitionInBlock
        self.attrs += [:zip_code]
        self.required_attrs = [:email]
        attr_accessor :zip_code
      end

      it 'copies validation errors from person model' do
        person = TestPerson.new(zip_code: 'test')
        expect(person).to have(1).error_on(:zip_code)
      end

      it 'does not duplicate errors errors from person model' do
        person = TestPerson.new(email: 'top_leader@example.com')
        expect(person).to have(1).error_on(:email)
        expect(person.errors['email'].first).to start_with('ist bereits vergeben')
      end
    end
  end

  describe 'delegations' do
    it 'reads gender label from person' do
      mate.gender = 'm'
      expect(mate.gender_label).to eq 'männlich'
    end

    it 'reflects on association on person' do
      expect(mate.class.reflect_on_association(:phone_numbers)).to be_kind_of(ActiveRecord::Reflection::HasManyReflection)
    end

    it 'reads human attribute name from person on association on person' do
      expect(mate.class.human_attribute_name(:first_name)).to eq 'Vorname'
    end

    it 'save! calls save!' do
      mate.first_name = 'test'
      expect { mate.save! }.to change { Person.count }.by(1)
    end

    it 'save! raises as expected' do
      expect { mate.save! }.to raise_error
    end
  end
end
