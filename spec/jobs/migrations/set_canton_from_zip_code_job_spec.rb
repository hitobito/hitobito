# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Migrations::SetCantonFromZipCodeJob do
  def run = described_class.new.perform

  def create_person(canton: nil, country: "CH", zip_code: nil)
    Fabricate(:person).tap do |person|
      person.update_columns(country:, canton:, zip_code:)
    end
  end

  before { Location.create!(zip_code: 3000, name: "Bern", canton: "be") }

  it "fills a blank canton from a matching location" do
    person = create_person(zip_code: 3000)
    run
    expect(person.reload.canton).to eq "be"
  end

  it "also fills a blank country" do
    person = create_person(zip_code: 3000, country: nil)
    run
    expect(person.reload.country).to eq "CH"
  end

  it "never overrides an already-set canton" do
    person = create_person(canton: "zh", zip_code: 3000)
    run
    expect(person.reload.canton).to eq "zh"
  end

  it "never overrides an already-set country" do
    person = create_person(country: "DE", zip_code: 3000)
    run
    expect(person.reload.country).to eq "DE"
  end

  it "does not fill canton for a person with an explicit non-swiss country" do
    person = create_person(country: "DE", zip_code: 3000)
    run
    expect(person.reload.canton).to be_nil
  end

  it "does nothing without a zip_code" do
    person = create_person(zip_code: nil)
    run
    expect(person.reload.canton).to be_nil
  end

  it "does nothing when the zip_code matches no location" do
    person = create_person(zip_code: 9999)
    run
    expect(person.reload.canton).to be_nil
  end

  it "does not run at all when the instance does not default to Switzerland" do
    person = create_person(zip_code: 3000, country: nil)
    allow(Countries).to receive(:default).and_return("de")
    run
    expect(person.reload.canton).to be_nil
    expect(person.reload.country).to be_nil
  end
end
