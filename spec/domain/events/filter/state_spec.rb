# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::State do
  let(:base_scope) { Event.all }

  subject(:filter) { described_class.new(:state, params, Event::Course) }

  let!(:event_created) do
    Fabricate(:course, state: "created")
  end

  let!(:event_confirmed) do
    Fabricate(:course, state: "confirmed")
  end

  let!(:event_canceled) do
    Fabricate(:course, state: "canceled")
  end

  before { Event::Course.possible_states = %w[created confirmed closed canceled] }
  after { Event::Course.possible_states = [] }

  context "with a possible state" do
    let(:params) { {states: ["created"]} }

    it "includes only events with the specified state" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(1)
      expect(result).to include(event_created)
    end
  end

  context "with multiple possible states" do
    let(:params) { {states: ["created", "confirmed"]} }

    it "includes events with any of the specified states" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(2)
      expect(result).to include(event_created)
      expect(result).to include(event_confirmed)
      expect(result).not_to include(event_canceled)
    end
  end

  context "with a not possible state" do
    let(:params) { {states: ["blørbaël"]} }

    it "does not pass on the wrong state into sql" do
      result = filter.apply(base_scope)
      expect(result.to_sql).not_to include("blørbaël")
    end

    it "returns no results" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(0)
    end
  end
end
