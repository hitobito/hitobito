# frozen_string_literal: true

#  Copyright (c) 2012-2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
require "spec_helper"

describe Export::Tabular::People::HouseholdRow do
  def name(first_names = [], last_names = [])
    person = Person.new(first_name: first_names.join(","),
                        last_name: last_names.join(","))
    described_class.new(person).name
  end

  it "shows the company name for companies" do
    person = Person.new(first_name: "Tom", last_name: "Tester",
                        company: true, company_name: "ACME Corp.")

    expect(described_class.new(person).name).to eq "ACME Corp."
  end

  it "handles nil first and last name" do
    expect(described_class.new(Person.new).name).to eq ""
  end

  it "treats blank last name as first present lastname" do
    expect(name(%w(Andreas Mara), ["Mäder", ""]))
      .to eq "Andreas und Mara Mäder"

    expect(name(%w(Andreas Mara Blunsch), ["Mäder", "", "Wyss"]))
      .to eq "Andreas und Mara Mäder, Blunsch Wyss"

    expect(name(%w(Andreas Mara Rahel Blunsch), ["Mäder", "", "Emmenegger", ""]))
      .to eq "Andreas, Mara und Blunsch Mäder, Rahel Emmenegger"

    expect(name(%w(Andreas Mara), ["", ""]))
      .to eq "Andreas und Mara"
  end

  it "does not output anything if first and last names are blank" do
    expect(name([""], [""])).to be_blank
    expect(name([nil, nil], [nil])).to be_blank
  end

  it "combines two people with same last_name" do
    expect(name(%w(Andreas Mara), %w(Mäder Mäder))).to eq "Andreas und Mara Mäder"
  end

  it "combines multiple people with same last_name" do
    expect(name(%w(Andreas Mara Ruedi), %w(Mäder Mäder Mäder)))
      .to eq "Andreas, Mara und Ruedi Mäder"
  end

  it "joins two different names by SEPARATOR" do
    expect(name(%w(Andreas Rahel), %w(Mäder Steiner))).to eq "Andreas Mäder, Rahel Steiner"
  end

  it "reduces first names to initial if line is too long" do
    aggregated = name(%w(Andreas Rahel Rahel Blunsch), %w(Mäder Steiner Emmenegger Wyss))
    expect(aggregated).to eq "A. Mäder, R. Steiner, R. Emmenegger, B. Wyss"
  end
end
