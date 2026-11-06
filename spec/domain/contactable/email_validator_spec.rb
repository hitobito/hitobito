# frozen_string_literal: true

#
#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Contactable::EmailValidator do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  describe "tagging" do
    let(:validator) { described_class.new }

    before { allow(Truemail).to receive(:valid?).and_call_original }

    it "ignores person with blank email" do
      top_leader.email = nil
      top_leader.save!(validate: false)
      validator.validate_people
      expect(taggings_for(top_leader).count).to eq(0)
    end

    it "tags people with invalid primary e-mail" do
      top_leader.update_columns(email: "not-an-email")

      validator.validate_people

      expect(taggings_for(top_leader).count).to eq(1)
      leader_tagging = taggings_for(top_leader).first
      expect(leader_tagging.tag.name).to eq("category_validation:email_primary_invalid")
      expect(leader_tagging.context).to eq("tags")
      expect(leader_tagging.hitobito_tooltip).to eq("not-an-email")
    end

    it "keeps existing invalid e-mail tag" do
      top_leader.update_columns(email: "not-an-email")
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
      top_leader.update_columns(email: "not-an-email")
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
  end

  describe "blocking" do
    let(:validator) { described_class.new(block: true) }
    let(:invalid_domains) { ["@domainungueltig42.ch", "@#{Settings.email.list_domain}"] }

    before do
      allow(Truemail).to receive(:valid?) { |email| !email.end_with?(*invalid_domains) }
      allow(FeatureGate).to receive(:enabled?).and_call_original
    end

    it "blocks an invalid primary e-mail with a new bounce" do
      top_leader.update_columns(email: "leader@domainungueltig42.ch")

      validator.validate_people

      bounce = Bounce.find_by(email: "leader@domainungueltig42.ch")
      expect(bounce).to be_blocked
      expect(bounce.count).to eq(0)
      expect(taggings_for(top_leader).count).to eq(1)
    end

    it "blocks every invalid additional e-mail" do
      create_invalid_additional_email(bottom_member, "a@domainungueltig42.ch")
      create_invalid_additional_email(bottom_member, "b@domainungueltig42.ch")

      validator.validate_people

      expect(Bounce.blocked.pluck(:email))
        .to match_array %w[a@domainungueltig42.ch b@domainungueltig42.ch]
      expect(taggings_for(bottom_member).first.hitobito_tooltip)
        .to eq("a@domainungueltig42.ch b@domainungueltig42.ch")
    end

    it "blocks an existing bounce and keeps its count" do
      top_leader.update_columns(email: "leader@domainungueltig42.ch")
      bounce = Bounce.create!(email: "leader@domainungueltig42.ch", count: 1)

      expect { validator.validate_people }.not_to change(Bounce, :count)

      expect(bounce.reload).to be_blocked
      expect(bounce.count).to eq(1)
    end

    it "does not block valid e-mails" do
      expect { validator.validate_people }.not_to change(Bounce, :count)
    end

    it "only tags e-mails of the application domain" do
      top_leader.update_columns(email: "leader@#{Settings.email.list_domain}")

      expect { validator.validate_people }.not_to change(Bounce, :count)
      expect(taggings_for(top_leader).count).to eq(1)
    end

    it "only tags if bounces are disabled" do
      allow(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(false)
      top_leader.update_columns(email: "leader@domainungueltig42.ch")

      expect { validator.validate_people }.not_to change(Bounce, :count)
      expect(taggings_for(top_leader).count).to eq(1)
    end

    it "only tags without the block option" do
      top_leader.update_columns(email: "leader@domainungueltig42.ch")

      expect { described_class.new.validate_people }.not_to change(Bounce, :count)
      expect(taggings_for(top_leader).count).to eq(1)
    end
  end

  private

  def taggings_for(person)
    ActsAsTaggableOn::Tagging
      .where(taggable: person)
  end

  def create_invalid_additional_email(person, email)
    AdditionalEmail
      .new(contactable: person,
        email: email,
        category: contact_account_categories(:additional_email_person_other))
      .save!(validate: false)
  end
end
