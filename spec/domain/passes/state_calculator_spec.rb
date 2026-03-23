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

      it "defaults valid_from to current date" do
        expect(calculator.validity_dates[:valid_from]).to eq(Date.current)
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

  describe "#update_state!" do
    context "when person has active matching roles" do
      let(:person) { people(:top_leader) }

      it "updates pass to eligible state with validity dates" do
        person.roles.first.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: 1.year.from_now.to_date
        )
        
        calculator.update_state!(pass)
        
        expect(pass.reload.state).to eq("eligible")
        expect(pass.valid_from).to eq(1.year.ago.to_date)
        expect(pass.valid_until).to eq(1.year.from_now.to_date)
      end
    end

    context "when person has only ended matching roles" do
      let(:person) { people(:top_leader) }

      it "updates pass to ended state with validity dates" do
        person.roles.first.update_columns(
          start_on: 2.years.ago.to_date,
          end_on: 1.day.ago.to_date
        )
        
        calculator.update_state!(pass)
        
        expect(pass.reload.state).to eq("ended")
        expect(pass.valid_from).to eq(2.years.ago.to_date)
        expect(pass.valid_until).to eq(1.day.ago.to_date)
      end
    end

    context "when person has no matching roles" do
      let(:person) { Fabricate(:person) }

      it "updates pass to revoked state with nil dates" do
        calculator.update_state!(pass)
        
        expect(pass.reload.state).to eq("revoked")
        expect(pass.valid_from).to be_nil
        expect(pass.valid_until).to be_nil
      end
    end
  end
end
