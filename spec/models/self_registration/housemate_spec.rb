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
    it 'validates 5 fields for presence' do
      expect(mate).not_to be_valid
      expect(mate.errors).to have(4).items
      expect(mate.errors.attribute_names).to eq [
        :first_name,
        :last_name,
        :email,
        :birthday
      ]
    end

    it 'validates email for syntax' do
      mate.required_attrs = [:email]
      mate.email = 'test'
      expect(mate).to have(1).error_on(:email)
      expect(mate.errors[:email]).to eq(["ist nicht gültig"])
    end

    it 'validates email for uniqueness' do
      mate.required_attrs = [:email]
      mate.email = 'top_leader@example.com'
      expect(mate).to have(1).error_on(:email)
      expect(mate.errors[:email][0]).to start_with("ist bereits vergeben. Diese Adresse muss")
    end

    it 'accepts email once in household' do
      mate.required_attrs = [:email]
      mate.household_emails = %w(test@example.com)
      mate.email = 'top.leader@example.com'
      expect(mate).to have(0).error_on(:email)
    end

    it 'validates email only occurs once in household' do
      mate.required_attrs = [:email]
      mate.household_emails = %w(test@example.com test@example.com)
      mate.email = 'test@example.com'
      expect(mate).to have(1).error_on(:email)
      expect(mate.errors[:email][0]).to start_with("ist bereits vergeben. Diese Adresse muss")
    end

    it 'validates role' do
      group = groups(:top_group)
      group.update_columns(self_registration_role_type: 'Group::TopLayer::TopAdmin')
      mate.required_attrs = [:first_name]
      mate.first_name = 'test'
      mate.primary_group = group
      expect(mate).not_to be_valid
      expect(mate).to have(1).error_on(:type)
      expect(mate.errors[:type]).to eq(['kann hier nicht erstellt werden'])
    end

    describe 'person validations' do
      def stub_test_person
        stub_const("TestPerson", Class.new(SelfRegistration::Person) do # rubocop:disable Lint/ConstantDefinitionInBlock
          self.attrs = [:zip_code, :primary_group]
        end)
      end

      before { stub_test_person }

      it 'copies validation errors from person model' do
        person = TestPerson.new(zip_code: 'test')
        expect(person).to have(1).error_on(:zip_code)
        expect(person.errors[:zip_code]).to eq(['ist nicht gültig'])
      end

      it 'does not duplicate errors errors from person model' do
        person = TestPerson.new(email: 'top_leader@example.com')
        expect(person).to have(1).error_on(:email)
        expect(person.errors[:email][0]).to start_with("ist bereits vergeben. Diese Adresse muss")
      end
    end
  end

  describe 'delegations' do
    it 'reads gender label from person' do
      mate.gender = 'm'
      expect(mate.gender_label).to eq 'männlich'
    end

    it 'reflects on association on person' do
      expect(mate.class.reflect_on_association(:phone_numbers))
        .to be_kind_of(ActiveRecord::Reflection::HasManyReflection)
    end

    it 'reads human attribute name from person on association on person' do
      expect(mate.class.human_attribute_name(:first_name)).to eq 'Vorname'
    end
  end

  describe '#save!' do
    let(:role_type) { Group::TopGroup::Member }
    let(:group) { groups(:top_group).tap { |g| g.update!(self_registration_role_type: role_type) } }

    it 'saves person and role' do
      mate.first_name = 'test'
      mate.primary_group = group
      expect(mate.person).to be_valid
      expect { mate.save! }
        .to change { Person.count }.by(1)
        .and change { group.roles.where(type: role_type.sti_name).count }.by(1)
    end

    it 'save! raises as expected' do
      expect { mate.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
