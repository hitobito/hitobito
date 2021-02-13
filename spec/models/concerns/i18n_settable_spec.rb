# encoding: utf-8

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe I18nSettable do

  let(:person) { Person.new(first_name: "Dummy") }

  it "sets i18n attribute as basic value" do
    person.gender = "m"
    expect(person.gender).to eq "m"
    person.gender = "w"
    expect(person.gender).to eq "w"
    person.gender = ""
    expect(person.gender).to eq ""
  end

  it "sets i18n attribute in german" do
    person.gender = "männlich"
    expect(person.gender).to eq "m"
    person.gender = "weiblich"
    expect(person.gender).to eq "w"
    person.gender = "unbekannt"
    expect(person.gender).to eq nil
    expect(person).to be_valid
  end

  it "sets i18n attribute in french" do
    I18n.locale = :fr
    person.gender = "masculin"
    expect(person.gender).to eq "m"
    person.gender = "féminin"
    expect(person.gender).to eq "w"
    person.gender = "inconnu"
    expect(person.gender).to eq nil
    expect(person).to be_valid
    I18n.locale = :de
  end

  it "sets invalid i18n attribute in german" do
    person.gender = "foo"
    expect(person.gender).to eq "foo"
    expect(person).not_to be_valid
  end

  it "sets invalid i18n attribute in french" do
    I18n.locale = :fr
    person.gender = "weiblich"
    expect(person.gender).to eq "weiblich"
    expect(person).not_to be_valid
    I18n.locale = :de
  end

  it "sets i18n boolean attribute in german" do
    person.company = "JA"
    expect(person.company).to eq true
    person.company = "Nein"
    expect(person.company).to eq false
  end

  it "sets i18n boolean attribute in french" do
    I18n.locale = :fr
    person.company = "ouI"
    expect(person.company).to eq true
    person.company = "non"
    expect(person.company).to eq false
    I18n.locale = :de
  end

  it "sets invalid i18n boolean attribute to true" do
    person.company = "any"
    expect(person.company).to eq true
  end

  it "sets i18n boolean attribute as boolean" do
    person.company = true
    expect(person.company).to eq true
    person.company = false
    expect(person.company).to eq false
  end

  it "sets i18n boolean attribute as integer" do
    person.company = 1
    expect(person.company).to eq true
    person.company = 0
    expect(person.company).to eq false
  end

  it "sets i18n boolean attribute as integer string" do
    person.company = "1"
    expect(person.company).to eq true
    person.company = "0"
    expect(person.company).to eq false
  end

  it "sets i18n boolean attribute as boolean string" do
    person.company = "true"
    expect(person.company).to eq true
    person.company = "false"
    expect(person.company).to eq false
  end

  it "sets i18n boolean attribute as empty string" do
    person.company = " "
    expect(person.company).to eq false
  end

  it "sets i18n boolean attribute nil" do
    person.company = nil
    expect(person.company).to eq false
  end

end
