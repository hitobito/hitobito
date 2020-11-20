# frozen_string_literal: true

require 'spec_helper'

describe Contactable::AddressValidator do
  let(:validator) { described_class.new }
  let(:person) { people(:bottom_member) }

  it 'tags people with invalid address' do
    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(1)

    tagging = ActsAsTaggableOn::Tagging.find_by(taggable: person, hitobito_tooltip: person.address)

    expect(tagging).to be_present
    expect(tagging.tag).to eq(PersonTags::Validation.address_invalid)
  end

  it 'does not tag people from non imported countries' do
    person.update!(country: 'DE')

    expect do
      validator.validate_people
    end.to_not change { ActsAsTaggableOn::Tagging.count }
  end

  it 'does not tag people if tagged as override' do
    ActsAsTaggableOn::Tagging
      .create!(taggable: person,
               context: :tags,
               tag: PersonTags::Validation.invalid_address_override(create: true))

    expect do
      validator.validate_people
    end.to_not change { ActsAsTaggableOn::Tagging.count }
  end

  it 'tags people only once' do
    expect do
      validator.validate_people
    end.to change { ActsAsTaggableOn::Tagging.count }.by(1)

    expect do
      validator.validate_people
    end.to_not change { ActsAsTaggableOn::Tagging.count }
  end
end
