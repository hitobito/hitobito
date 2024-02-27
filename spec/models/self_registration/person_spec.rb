# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe SelfRegistration::Person do
  subject(:model) { TestPerson.new }

  def stub_test_person
    stub_const("TestPerson", Class.new(described_class) do # rubocop:disable Lint/ConstantDefinitionInBlock
      yield self
    end)
  end

  describe '::human_attribute_name' do
    it 'reads value from person' do
      expect(Person.human_attribute_name(:email)).to eq 'Haupt-E-Mail'
    end

    it 'simply humanizes if value is not defined' do
      expect(Person.human_attribute_name(:missing_attr)).to eq 'Missing attr'
    end
  end

  it 'validates email is not taken' do
    stub_test_person do |person|
      person.attrs = [:email, :primary_group]
      person.required_attrs = [:email]
    end

    model.email = 'top_leader@example.com'
    expect(model).to have(1).error_on(:email)

    error = <<-ERROR.squish << "\n"
      Haupt-E-Mail ist bereits vergeben. Diese Adresse muss für alle Personen eindeutig sein, da sie
      beim Login verwendet wird. Du kannst jedoch unter 'Weitere E-Mails' Adressen eintragen, welche
      bei anderen Personen als Haupt-E-Mail vergeben sind (Die Haupt-E-Mail kann leer gelassen
      werden).
    ERROR

    expect(model.errors.full_messages).to eq [error]
  end

  context '::human_attribute_name' do
    it 'uses translations of model' do
      with_translations(
        de: {
          activemodel: { attributes: { 'self_registration/person': { imaginary_attribute: 'test_person#imaginary' } } },
          activerecord: { attributes: { person: { imaginary_attribute: 'person#imaginary' } } }
        }
      ) do
        expect(described_class.human_attribute_name(:imaginary_attribute)).to eq 'test_person#imaginary'
      end
    end

    it 'falls back to Person translations' do
      with_translations(
        de: {
          activerecord: { attributes: { person: { imaginary_attribute: 'person#imaginary' } } }
        }
      ) do
        expect(described_class.human_attribute_name(:imaginary_attribute)).to eq 'person#imaginary'
      end
    end
  end

  describe '#save!'  do
    let(:group) { groups(:top_layer) }
    let(:jobs) { Delayed::Job.where("handler like '%person_id: #{model.person.id}%'") }

    before do
      stub_test_person do |person|
        person.attrs = [:first_name, :email, :primary_group]
        person.required_attrs = [:email]
      end

      group.update!(self_registration_role_type: group.role_types.first)

      model.first_name = 'test'
      model.primary_group = groups(:top_layer)
      model.email = 'test@example.com'
    end

    it 'creates person, role and duplicate locator job' do
      expect { model.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and change { jobs.count }.by(1)
    end
  end
end
