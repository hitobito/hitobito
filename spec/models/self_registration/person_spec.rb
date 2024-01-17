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
end
