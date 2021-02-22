# frozen_string_literal: true

#
#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Contactable::EmailValidator do
  let(:validator) { described_class.new }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before { allow(Truemail).to receive(:valid?).and_call_original }

  it "ignores person with blank email" do
    top_leader.email = nil
    top_leader.save!(validate: false)
    validator.validate_people
    expect(taggings_for(top_leader).count).to eq(0)
  end

  it "tags people with invalid primary e-mail" do
    top_leader.email = "not-an-email"
    top_leader.save!(validate: false)

    validator.validate_people

    expect(taggings_for(top_leader).count).to eq(1)
    leader_tagging = taggings_for(top_leader).first
    expect(leader_tagging.tag.name).to eq("category_validation:email_primary_invalid")
    expect(leader_tagging.context).to eq("tags")
    expect(leader_tagging.hitobito_tooltip).to eq("not-an-email")
  end

  it "keeps existing invalid e-mail tag" do
    top_leader.email = "not-an-email"
    top_leader.save!(validate: false)
    create_invalid_additional_email(top_leader, "not-an-email")

    validator.validate_people

    expect(taggings_for(top_leader).count).to eq(2)

    validator.validate_people

    leader_tagging_primary = taggings_for(top_leader).first
    expect(leader_tagging_primary.tag.name).to eq("category_validation:email_primary_invalid")

    leader_tagging_additional = taggings_for(top_leader).second
    expect(leader_tagging_additional.tag.name).to eq("category_validation:email_additional_invalid")
  end

  it "tags people with invalid additional e-mail" do
    create_invalid_additional_email(bottom_member, "not-an-email")
    create_invalid_additional_email(bottom_member, "mail@nodomain")

    validator.validate_people

    expect(taggings_for(bottom_member).count).to eq(1)
    member_tagging = taggings_for(bottom_member).first
    expect(member_tagging.tag.name).to eq("category_validation:email_additional_invalid")
    expect(member_tagging.context).to eq("tags")
    expect(member_tagging.hitobito_tooltip).to eq("not-an-email mail@nodomain")
  end

  it "tags people with invalid primary and additional e-mail" do
    top_leader.email = "not-an-email"
    top_leader.save!(validate: false)
    create_invalid_additional_email(top_leader, "not-an-email")

    validator.validate_people

    expect(taggings_for(top_leader).count).to eq(2)

    leader_tagging_primary = taggings_for(top_leader).first
    expect(leader_tagging_primary.tag.name).to eq("category_validation:email_primary_invalid")
    expect(leader_tagging_primary.context).to eq("tags")
    expect(leader_tagging_primary.hitobito_tooltip).to eq("not-an-email")

    leader_tagging_additional = taggings_for(top_leader).second
    expect(leader_tagging_additional.tag.name).to eq("category_validation:email_additional_invalid")
    expect(leader_tagging_additional.context).to eq("tags")
    expect(leader_tagging_additional.hitobito_tooltip).to eq("not-an-email")
  end

  private

  def taggings_for(person)
    ActsAsTaggableOn::Tagging
      .where(taggable: person)
  end

  def create_invalid_additional_email(person, email)
    AdditionalEmail
      .new(contactable: person,
           email: email)
      .save!(validate: false)
  end
end
