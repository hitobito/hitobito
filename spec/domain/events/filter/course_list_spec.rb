# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::CourseList do
  let(:user) { people(:bottom_member) }

  before do
    @top_group_course = Fabricate(
      :course,
      groups: [groups(:top_group)],
      state: "created",
      globally_visible: false
    )
    @bottom_course1 = Fabricate(
      :course,
      groups: [groups(:bottom_layer_one)],
      globally_visible: false
    )
    @bottom_course2 = Fabricate(
      :course,
      groups: [groups(:bottom_layer_one)],
      state: "created",
      globally_visible: true
    )
    @bottom2_course1 = Fabricate(
      :course,
      groups: [groups(:bottom_layer_two)],
      state: "created",
      globally_visible: false
    )
    @bottom2_course2 = Fabricate(
      :course,
      groups: [groups(:bottom_layer_two)],
      state: "created",
      globally_visible: true
    )
    travel_to(Time.zone.local(2012, 3, 1))
  end

  def list_entries(params = {})
    described_class.new(user, params).entries
  end

  it "contains only events in user hierarchy or globally visible" do
    entries = list_entries
    expect(entries.map(&:id)).to match_array([@bottom_course1, @bottom_course2, @bottom2_course2,
      events(:top_course)].map(&:id))
  end

  it "contains all events with list_all_courses" do
    entries = list_entries(list_all_courses: true)
    expect(entries.size).to eq(6)
  end

  context "filters" do
    after { Event::Course.possible_states = [] }

    it "by group and state" do
      Event::Course.possible_states = %w[created closed canceled]
      entries = list_entries(filters: {groups: {ids: [groups(:bottom_layer_one).id]},
                                       state: {states: ["created", "closed"]}})
      expect(entries).to eq [@bottom_course2]
    end
  end

  context "with event kind" do
    before do
      expect_any_instance_of(described_class).to receive(:kind_used?).at_least(:once).and_return(false)
    end

    it "does not load kind translations" do
      expect(list_entries.to_sql).not_to include("event_kind_translations")
    end
  end
end
