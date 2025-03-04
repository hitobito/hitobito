# frozen_string_literal: true

#  Copyright (c) 2020-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Contactable::AddressValidator do
  let(:validator) { described_class.new }
  let(:person) { people(:bottom_member) }
  let(:address) { addresses(:bs_bern) }

  it "tags people with invalid address" do
    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(1)

    tagging = ActsAsTaggableOn::Tagging.find_by(taggable: person, hitobito_tooltip: person.address)

    expect(tagging).to be_present
    expect(tagging.tag).to eq(PersonTags::Validation.address_invalid)
  end

  it "removes tagging from people with valid address" do
    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(1)

    tagging = ActsAsTaggableOn::Tagging.find_by(taggable: person, hitobito_tooltip: person.address)

    expect(tagging).to be_present
    expect(tagging.tag).to eq(PersonTags::Validation.address_invalid)

    street, number = Address::Parser.new(person.address).parse
    street_attrs = [:street_short,
      :street_short_old,
      :street_long,
      :street_long_old].index_with { |_k| street }

    Address.create!(street_attrs.merge(zip_code: person.zip_code,
      town: person.town,
      state: "BE",
      numbers: [number]))

    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(-1)

    tagging = ActsAsTaggableOn::Tagging.find_by(taggable: person, hitobito_tooltip: person.address)

    expect(tagging).to_not be_present
  end

  it "does not remove nonexistent tagging from people with valid address" do
    street, number = Address::Parser.new(person.address).parse
    street_attrs = [:street_short,
      :street_short_old,
      :street_long,
      :street_long_old].index_with { |_k| street }

    Address.create!(street_attrs.merge(zip_code: person.zip_code,
      town: person.town,
      state: "BE",
      numbers: [number]))

    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(0)

    tagging = ActsAsTaggableOn::Tagging.find_by(taggable: person, hitobito_tooltip: person.address)

    expect(tagging).to_not be_present
  end

  it "does not tag person with valid address without street number" do
    person.street = address.street_short
    person.housenumber = nil
    person.zip_code = address.zip_code
    person.town = address.town
    person.save!

    expect do
      validator.validate_people
    end.to_not(change { ActsAsTaggableOn::Tagging.count })
  end

  it "does not tag person with valid address with street number" do
    person.street = address.street_short
    person.housenumber = address.numbers.first
    person.zip_code = address.zip_code
    person.town = address.town
    person.save!

    expect do
      validator.validate_people
    end.to_not(change { ActsAsTaggableOn::Tagging.count })
  end

  it "does not tag person with valid address but invalid housenumber" do
    person.street = address.street_short
    person.housenumber = "1234"
    person.zip_code = address.zip_code
    person.town = address.town
    person.save!

    expect do
      validator.validate_people
    end.to(change { ActsAsTaggableOn::Tagging.count })
  end

  it "does not tag people from non imported countries" do
    person.update!(country: "DE", zip_code: "12345")

    expect do
      validator.validate_people
    end.to_not(change { ActsAsTaggableOn::Tagging.count })
  end

  it "does not tag people if tagged as override" do
    ActsAsTaggableOn::Tagging
      .create!(taggable: person,
        context: :tags,
        tag: PersonTags::Validation.invalid_address_override(create: true))

    expect do
      validator.validate_people
    end.to_not(change { ActsAsTaggableOn::Tagging.count })
  end

  it "does not tag people if already tagged as invalid" do
    ActsAsTaggableOn::Tagging
      .create!(taggable: person,
        context: :tags,
        hitobito_tooltip: person.address,
        tag: PersonTags::Validation.address_invalid(create: true))

    expect do
      validator.validate_people
    end.to_not(change { ActsAsTaggableOn::Tagging.count })
  end

  it "tags people only once" do
    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(1)

    expect do
      validator.validate_people
    end.to_not(change { ActsAsTaggableOn::Tagging.count })
  end
end
