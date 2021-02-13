# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ListsController do
  render_views
  before { sign_in(person) }

  let(:person) { people(:bottom_member) }

  context "GET #events" do
    it "populates events in group_hierarchy, order by start_at" do
      a = create_event(:bottom_layer_one)
      b = create_event(:top_layer, start_at: 1.year.ago)

      get :events

      expect(assigns(:grouped_events).values).to eq [[b], [a]]
    end

    it "does not include courses" do
      create_event(:top_layer, type: :course)

      get :events

      expect(assigns(:grouped_events)).to be_empty
    end

    it "groups by month" do
      create_event(:top_layer, start_at: Time.zone.parse("2012-10-30"))
      create_event(:top_layer, start_at: Time.zone.parse("2012-11-1"))

      get :events

      expect(assigns(:grouped_events).keys).to eq(["Oktober 2012", "November 2012"])
    end
  end

  context "GET #courses" do
    context "filters by year" do
      let(:year) { Date.today.year }
      let(:year_range) { (year - 2..year + 1) }

      it "defaults to current year" do
        get :courses
        expect(assigns(:year)).to eq year
        expect(controller.send(:year_range)).to eq year_range
      end

      it "reads year from params, populates vars" do
        get :courses, params: {year: 2010}
        expect(assigns(:year)).to eq 2010
        expect(controller.send(:year_range)).to eq 2008..2011
      end

      it "groups by course kind" do
        get :courses, params: {year: 2012}
        expect(assigns(:grouped_events).keys).to eq ["Scharleiterkurs"]
      end
    end

    context "filter per group" do
      before { sign_in(people(:top_leader)) }

      it "defaults to layer of primary group" do
        get :courses
        expect(assigns(:group_id)).to eq groups(:top_group).layer_group_id
      end

      it "can be set via param, only if year is present" do
        get :courses, params: {year: 2010, group_id: groups(:top_layer).id}
        expect(assigns(:group_id)).to eq groups(:top_layer).id
      end
    end

    context "finds course offerer" do
      it "via primary group" do
        sign_in(people(:top_leader))
        get :courses
        expect(controller.send(:course_group_from_primary_layer)).to eq groups(:top_layer)
      end

      it "via hierarchy" do
        group = groups(:bottom_group_one_one)
        user = Fabricate(Group::BottomGroup::Leader.name.to_s, label: "foo", group: group).person
        sign_in(user)
        get :courses
        expect(controller.send(:course_group_from_hierarchy).id).to eq groups(:bottom_layer_one).id
      end
    end

    context "exports to csv" do
      let(:rows) { response.body.split("\n") }
      let(:course) { Fabricate(:course) }

      before { Fabricate(:event_date, event: course) }

      it "renders csv headers" do
        allow(controller).to receive_messages(current_user: people(:root))
        get :courses, format: :csv
        expect(response).to be_successful
        expect(rows.first).to match(/^Name;Organisatoren;Kursnummer;Kursart;.*;Anzahl Anmeldungen$/)
        expect(rows.size).to eq(2)
      end
    end

    context "without kind_id" do
      before { Event::Course.used_attributes -= [:kind_id] }

      it "groups by month" do
        get :courses, params: {year: 2012}
        expect(assigns(:grouped_events).keys).to eq(["März 2012"])
      end

      after { Event::Course.used_attributes += [:kind_id] }
    end

    context "booking info" do
      before do
        course = Fabricate(:course, display_booking_info: false)
        Fabricate(:event_date, event: course, start_at: Date.new(2012, 1, 23))
      end

      it "is visible for manager" do
        sign_in(people(:top_leader))
        get :courses, params: {year: 2012}
        expect(response.body).to have_selector("tbody tr", count: 2)
        expect(response.body).to have_selector("tbody tr:nth-child(1) td:nth-child(3)",
          text: "0 Anmeldungen")
        expect(response.body).to have_selector("tbody tr:nth-child(2) td:nth-child(3)",
          text: "0 Anmeldungen")
      end

      it "is only visible for member where allowed by course" do
        sign_in(people(:bottom_member))
        get :courses, params: {year: 2012}
        expect(response.body).to have_selector("tbody tr", count: 2)
        expect(response.body).not_to have_selector("tbody tr:nth-child(1) td:nth-child(3)",
          text: "0 Anmeldungen")
        expect(response.body).to have_selector("tbody tr:nth-child(2) td:nth-child(3)",
          text: "0 Anmeldungen")
      end
    end
  end

  def create_event(group, hash = {})
    hash = {start_at: 4.days.ago, finish_at: 1.day.from_now, type: :event}.merge(hash)
    event = Fabricate(hash[:type], groups: [groups(group)])
    event.dates.create(start_at: hash[:start_at], finish_at: hash[:finish_at])
    event
  end
end
