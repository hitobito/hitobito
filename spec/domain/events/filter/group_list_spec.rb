# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::GroupList do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }

  before do
    @top_group_event = Fabricate(:event, groups: [groups(:top_group)])
    @bottom_group_event = Fabricate(:event, groups: [groups(:bottom_group_one_one)])
    travel_to(Time.zone.local(2012, 3, 1))
  end

  def list_entries(params = {})
    described_class.new(group, user, params).entries
  end

  context "range" do
    it "lists events of descendant groups by default" do
      expect(list_entries).to have(3).entries
    end

    it "lists events of descendant groups for filter deep" do
      expect(list_entries(range: "deep")).to have(3).entries
    end

    it "limits list to events of all non layer descendants" do
      entries = list_entries(range: "layer")
      expect(entries).to have(2).entries
      expect(entries).not_to include(@bottom_group_event)
    end

    it "limits list to events of all non layer descendants" do
      entries = list_entries(range: "group")
      expect(entries).to have(1).entries
      expect(entries).to include(events(:top_event))
    end
  end

  context "date params" do
    before do
      travel_back
      @bottom_group_event1 = Fabricate(
        :event,
        groups: [groups(:bottom_group_one_one)],
        dates: [Fabricate.build(:event_date, start_at: 5.days.ago, finish_at: 1.days.ago)]
      )
      @bottom_group_event2 = Fabricate(
        :event,
        groups: [groups(:bottom_group_one_one)],
        dates: [Fabricate.build(:event_date, start_at: 5.days.from_now, finish_at: 1.years.from_now)]
      )
    end

    it "lists events in current year by default" do
      expect(list_entries).to have(2).entries
    end

    it "lists upcoming events for given start_date" do
      expect(list_entries(start_date: Date.current)).to have(1).entries
    end

    it "lists upcoming events for given start_date includes overlapping" do
      expect(list_entries(start_date: 2.days.ago)).to have(2).entries
    end

    it "lists events from now to given end_date" do
      expect(list_entries(end_date: 5.days.from_now)).to have(1).entries
    end

    it "lists events for given dates" do
      Event::Date.create(event: events(:top_event), start_at: 11.years.from_now, finish_at: 12.years.from_now)
      expect(list_entries(start_date: 11.years.from_now, end_date: 12.years.from_now)).to have(1).entries
    end

    it "lists events on start date" do
      expect(list_entries(start_date: 5.days.ago, end_date: 5.days.ago)).to have(1).entries
    end

    it "lists events on finish date" do
      expect(list_entries(start_date: 1.days.ago, end_date: 1.days.ago)).to have(1).entries
    end

    it "does not raise error if dates invalid" do
      expect { list_entries(end_date: "inv'alid") }.not_to raise_error
      expect { list_entries(start_date: "inv'alid") }.not_to raise_error
    end
  end

  context "sort_expression" do
    it "sorts according to sort_expression" do
      expect(list_entries(range: "layer", sort_expression: "event_translations.name").first.name).to eq "Eventus"
      expect(list_entries(range: "layer", sort_expression: "event_translations.name desc").first.name).to eq "Top Event"
    end

    it "works with string sort condition" do
      entries = list_entries(sort_expression: "event_dates.start_at asc")
      expect(entries).to have(3).entries
      expect(entries.first.name).to eq("Top Event")
    end

    it "works with pagination" do
      Fabricate.times(20, :event, groups: [group])

      entries = list_entries(sort_expression: {"event_dates.start_at" => "asc"})

      expect(entries).to have(23).entries
      expect(entries.page(1).per(20)).to have(20).entries
      expect(entries.page(2).per(20)).to have(3).entries
    end
  end
end
