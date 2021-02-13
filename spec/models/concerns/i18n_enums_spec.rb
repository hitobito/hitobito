# encoding: utf-8

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe I18nEnums do
  let(:person) { Person.new(first_name: "Dummy") }

  it "returns translated labels" do
    person.gender = "m"
    expect(person.gender_label).to eq "männlich"
    person.gender = "w"
    expect(person.gender_label).to eq "weiblich"
    person.gender = nil
    expect(person.gender_label).to eq "unbekannt"
  end

  it "returns translated label in french" do
    I18n.locale = :fr
    person.gender = "m"
    expect(person.gender_label).to eq "Masculin"
    person.gender = "w"
    expect(person.gender_label).to eq "Féminin"
    person.gender = ""
    expect(person.gender_label).to eq "Inconnu"
    I18n.locale = :de
  end

  it "accepts only possible values" do
    person.gender = "m"
    expect(person).to be_valid
    person.gender = " "
    expect(person).to be_valid
    person.gender = nil
    expect(person).to be_valid
    person.gender = "foo"
    expect(person).not_to be_valid
  end

  it "has class side method to return all labels" do
    expect(Person.gender_labels).to eq({m: "männlich", w: "weiblich"})
  end
end
