# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

class Event::UnknownEvent < Event
  def assert_type_is_allowed_for_groups
    true
  end
end

describe Events::Filter::Type do
  let(:base_scope) { Event.all }

  subject(:filter) { described_class.new(:state, params, nil) }

  before do
    Event.destroy_all
  end

  let!(:event) do
    Fabricate(:event)
  end

  let!(:course) do
    Fabricate(:course)
  end

  let!(:other_event_type) do
    Event::UnknownEvent.create!(
      name: "Ghost Event",
      dates: [Event::Date.new(start_at: 1.day.ago)],
      groups: [groups(:top_group)]
    )
  end

  context "with a single type" do
    let(:params) { {types: ["Event::Course"]} }

    it "includes only events with specified type" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(1)
      expect(result).to include(course)
    end
  end

  context "with multiple types" do
    let(:params) { {types: ["Event::Course", "Event::UnknownEvent"]} }

    it "includes only events with specified type" do
      result = filter.apply(base_scope)
      expect(result.count).to eq(2)
      expect(result).to include(course, other_event_type)
    end
  end
end
