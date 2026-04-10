# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::StateCalculator do
  let(:group) { groups(:top_layer) }
  let(:pass_definition) { pass_definitions(:top_layer_pass) }
  let(:pass) { Fabricate(:pass, person: person, pass_definition: pass_definition) }
  let!(:grant) { pass_grants(:top_layer_grant) }

  subject(:calculator) { described_class.new(pass_definition, person) }

  describe "#state" do
    context "when person has an active matching role" do
      let(:person) { people(:top_leader) }

      it "returns :eligible" do
        expect(calculator.state).to eq(:eligible)
      end
    end

    context "when person has only ended matching roles" do
      let(:person) { people(:top_leader) }

      before do
        person.roles.first.update_columns(end_on: 1.day.ago.to_date)
      end

      it "returns :ended" do
        expect(calculator.state).to eq(:ended)
      end
    end

    context "when person has no matching roles" do
      let(:person) { Fabricate(:person) }

      it "returns :revoked" do
        expect(calculator.state).to eq(:revoked)
      end
    end
  end

  describe "#validity_dates" do
    context "when role has no end_on (open-ended)" do
      let(:person) { people(:top_leader) }

      before do
        person.roles.first.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: nil
        )
      end

      it "returns nil for valid_until" do
        expect(calculator.validity_dates[:valid_until]).to be_nil
      end

      it "still returns start_on as valid_from" do
        expect(calculator.validity_dates[:valid_from]).to eq(1.year.ago.to_date)
      end
    end

    context "when person has multiple roles and at least one is open-ended" do
      let(:person) { people(:top_leader) }

      before do
        # One role with a definite end date, one open-ended.
        # SQL MAX ignores NULLs and would wrongly return the definite end_on —
        # valid_until must be nil because the open-ended role keeps the pass active.
        person.roles.first.update_columns(
          start_on: 2.years.ago.to_date,
          end_on: 1.year.from_now.to_date
        )
        Fabricate(Group::TopGroup::Leader.sti_name,
          person: person,
          group: groups(:top_group),
          start_on: 1.year.ago.to_date,
          end_on: nil)
      end

      it "returns nil for valid_until" do
        expect(calculator.validity_dates[:valid_until]).to be_nil
      end

      it "returns the earliest start_on as valid_from" do
        expect(calculator.validity_dates[:valid_from]).to eq(2.years.ago.to_date)
      end
    end

    context "when person has matching roles" do
      let(:person) { people(:top_leader) }

      before do
        person.roles.first.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: 1.year.from_now.to_date
        )
      end

      it "returns start_on as valid_from" do
        expect(calculator.validity_dates[:valid_from]).to eq(1.year.ago.to_date)
      end

      it "returns end_on as valid_until" do
        expect(calculator.validity_dates[:valid_until]).to eq(1.year.from_now.to_date)
      end
    end

    context "when role has no start_on" do
      let(:person) { people(:top_leader) }

      before do
        person.roles.first.update_columns(start_on: nil)
      end

      it "returns nil for valid_from (no start constraint)" do
        expect(calculator.validity_dates[:valid_from]).to be_nil
      end
    end

    context "when person has no matching roles" do
      let(:person) { Fabricate(:person) }

      it "returns nil for both dates" do
        dates = calculator.validity_dates
        expect(dates[:valid_from]).to be_nil
        expect(dates[:valid_until]).to be_nil
      end
    end
  end
end
