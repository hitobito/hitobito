# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe Bounce do
  subject(:bounced) { described_class.create(email: "bounced@example.org", count: 1) }

  subject(:mailing_list_bounce) {
    described_class.create(email: "fourty-two@example.org", count: 2, mailing_list_ids: [1, 42])
  }

  subject(:blocked) { described_class.create(email: "blocked@example.org", count: 10, blocked_at: 1.day.ago) }

  it "has a block-threshold (can be overridden)" do
    expect(described_class::BLOCK_THRESHOLD).to eq 3
  end

  context "has a blocked-scope, which" do
    it "is a relation" do
      expect(described_class.blocked).to be_a ActiveRecord::Relation
    end

    it "equals none if feature is disabled" do
      allow(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(false)

      expect(described_class.blocked).to eq described_class.none
    end
  end

  context ".of_mailing_list" do
    let(:scope) { described_class.of_mailing_list(42) }

    it "returns a relation" do
      expect(scope).to be_a ActiveRecord::Relation
    end

    it "has the needed SQL" do
      expect(scope.to_sql).to include "mailing_list_ids @> ARRAY[42]::integer[])"
    end

    it "filters the right elements" do
      expect(mailing_list_bounce.mailing_list_ids).to include(42)

      expect(scope).to have(1).item
      expect(scope.first).to eq mailing_list_bounce
    end

    it "does not fail without an id" do
      expect(bounced.mailing_list_ids).to be_blank
      expect(blocked.mailing_list_ids).to be_blank

      scope = described_class.of_mailing_list(nil)

      expect(scope).to have(2).items
      expect(scope.to_a).to match_array [bounced, blocked]
    end
  end

  context ".record" do
    it "creates a record if none is exisiting" do
      expect do
        described_class.record("foo@example.com")
      end.to change(described_class, :count).by(1)
    end

    it "noops if email is from list_domain" do
      expect do
        described_class.record("foo@localhost")
      end.not_to change(described_class, :count)
    end

    it "returns the bounce-instance" do
      expect(described_class.record("foo@example.com")).to be_a described_class
    end

    it "increments the count if one is existing" do
      bounce = described_class.record("foo@example.com")

      expect do
        described_class.record("foo@example.com")
      end.to change { bounce.reload.count }.by(1)
    end

    it "stores the mailing_list_id" do
      bounce = described_class.record("foo@example.com", mailing_list_id: 23)

      expect(bounce.mailing_list_ids).to include 23
    end

    it "treats the mailing_list_id as optional" do
      bounce = described_class.record("foo@example.com", mailing_list_id: nil)
      expect(bounce.mailing_list_ids).to be_nil

      bounce = described_class.record("foo@example.com")
      expect(bounce.mailing_list_ids).to be_nil
    end

    it "extends the mailing_list_ids if adding to an existing bounce" do
      bounce = described_class.record("foo@example.com", mailing_list_id: 23)

      expect(bounce.mailing_list_ids).to include 23

      bounce = described_class.record("foo@example.com", mailing_list_id: 42)
      expect(bounce.mailing_list_ids).to include 42
      expect(bounce.mailing_list_ids).to match_array([23, 42])
    end

    it "only lists mailing_list_ids once if adding to an existing bounce" do
      bounce = described_class.record("foo@example.com", mailing_list_id: 23)

      expect(bounce.mailing_list_ids).to include 23

      bounce = described_class.record("foo@example.com", mailing_list_id: 23)

      expect(bounce.mailing_list_ids).to include 23
      expect(bounce.mailing_list_ids).to match_array([23])
    end

    it "does not change the timestamp of the original blocking" do
      expect do
        described_class.record(blocked.email)
      end.to_not change { blocked.reload.blocked_at }
    end
  end

  context ".blocked?" do
    before {
      bounced
      blocked
    } # call them to have the stored in the DB

    it "is true for blocked emails" do
      expect(described_class.blocked?("blocked@example.org")).to be_truthy
    end

    it "is false for bounced, but unblocked emails" do
      expect(described_class.blocked?("bounced@example.org")).to be_falsey
    end

    it "is false for unbounced emails" do
      expect(described_class.blocked?("unbounced@example.com")).to be_falsey
    end

    it "is false for nil" do
      expect(described_class.blocked?(nil)).to be_falsey
    end

    it "is false if feature is disabled" do
      allow(FeatureGate).to receive(:disabled?).with("email.bounces").and_return(true)

      expect(described_class.blocked?("blocked@example.org")).to be_falsey
      expect(described_class.blocked?("bounced@example.org")).to be_falsey
      expect(described_class.blocked?("unbounced@example.com")).to be_falsey
    end
  end

  context "#person" do
    it "finds the person by primary email" do
      person = Fabricate(:person, email: "person@example.org")
      bounce = described_class.create(email: person.email, count: 1)

      expect(bounce.person).to eq(person)
    end

    it "finds the person by additional email" do
      additional_email = "additional@example.org"
      person = Fabricate(:person)
      Fabricate(:additional_email, email: additional_email, contactable: person)

      bounce = described_class.create(email: additional_email, count: 1)

      expect(bounce.person).to eq(person)
    end
  end

  context "#people" do
    it "finds all people associated with that email-address" do
      first_person = Fabricate(:person, email: "person@example.org")
      second_person = Fabricate(:additional_email, email: "person@example.org").contactable

      bounce = described_class.create(email: "person@example.org", count: 1)

      expect(bounce.people).to match_array [first_person, second_person]
    end
  end

  context "#people_ids" do
    it "finds all people associated with that email-address" do
      first_person_id = Fabricate(:person, email: "person@example.org").id
      second_person_id = Fabricate(:additional_email, email: "person@example.org").contactable_id

      bounce = described_class.create(email: "person@example.org", count: 1)

      expect(bounce.people_ids).to match_array [first_person_id, second_person_id]
    end
  end

  context "#mailing_lists" do
    it "finds the mailing_lists that this email has bounce in" do
      mailing_list = Fabricate(:mailing_list, group: groups(:top_layer))

      bounce = described_class.record("person@example.org", mailing_list_id: mailing_list.id)

      expect(bounce.mailing_lists).to match_array [mailing_list]
    end
  end

  context "#block!" do
    it "marks a bounce as blocked" do
      expect do
        bounced.block!
      end.to change { bounced.reload.blocked? }.from(false).to(true)
    end

    it "returns the timestamp of blocking" do
      expect do
        expect(bounced.block!).to be_a DateTime
      end.to change { bounced.reload.blocked_at }.from(nil)
    end

    context "of a blocked email" do
      it "is accepted" do
        expect do
          blocked.block!
        end.to_not change { blocked.reload.blocked? }
      end

      it "returns the timestamp of the original blocking" do
        original_block_time = blocked.blocked_at

        expect do
          expect(blocked.block!).to eq original_block_time
        end.to_not change { blocked.reload.blocked_at }
      end
    end
  end

  context "#blocked?" do
    it "knows if an email is blocked" do
      expect(blocked).to be_blocked
    end

    it "knows if an email is not blocked" do
      expect(bounced).to_not be_blocked
    end

    it "can be disabled via FeatureGate" do
      allow(FeatureGate).to receive(:disabled?).with("email.bounces").and_return(true)

      expect(blocked).to_not be_blocked
      expect(bounced).to_not be_blocked
    end
  end
end
