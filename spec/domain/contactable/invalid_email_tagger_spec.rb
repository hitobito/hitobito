# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Contactable::InvalidEmailTagger do
  let(:person) { people(:top_leader) }

  it 'tags primary as invalid' do
    described_class.new(person, person.email, :primary).tag!
    expect(person).to have(1).tag
    expect(person.tags.first.name).to eq 'category_validation:email_primary_invalid'
    expect(person.taggings.first.hitobito_tooltip).to eq person.email
  end

  it 'tags additional email as invalid' do
    described_class.new(person, person.email, :additional).tag!
    expect(person).to have(1).tag
    expect(person.tags.first.name).to eq 'category_validation:email_additional_invalid'
    expect(person.taggings.first.hitobito_tooltip).to eq person.email
  end

  it 'does not re-tag already tagged person again' do
    2.times do
      described_class.new(person, person.email, :primary).tag!
      described_class.new(person, person.email, :additional).tag!
    end
    expect(person).to have(2).tags
  end

  it 'does not fail when a similar tag is already present' do
    ActsAsTaggableOn::Tagging.find_or_create_by!(
      taggable: person,
      context: :tags,
      tag: PersonTags::Validation.email_primary_invalid(create: true)
    )

    expect(person).to have(1).tag
    expect(person.tags.first.name).to eq 'category_validation:email_primary_invalid'

    expect do
      described_class.new(person, person.email, :primary).tag!
    end.to_not(change { person.tags.count })
  end
end
