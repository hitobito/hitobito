# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::CoursesController do
  render_views
  before do
    travel_to Time.zone.local(2020, 1, 1, 12)
    sign_in(person)
  end

  let(:person) { people(:bottom_member) }
  let(:filters) { assigns(:filter).chain }

  context "filters by date, it" do
    it "defaults to courses within a year from today" do
      get :index
      expect(filters.dig(:date_range, :since)).to eq "01.01.2020"
      expect(filters.dig(:date_range, :until)).to eq "01.01.2021"
    end

    it "reads since date from params, populates vars" do
      get :index, params: {filters: {date_range: {since: "03.04.2021"}}}
      expect(filters.dig(:date_range, :since)).to eq "03.04.2021"
      expect(filters.dig(:date_range, :until)).to be_nil
    end

    it "reads until date from params, populates vars" do
      get :index, params: {filters: {date_range: {until: "03.04.2021"}}}
      expect(filters.dig(:date_range, :since)).to be_nil
      expect(filters.dig(:date_range, :until)).to eq "03.04.2021"
    end

    it "reads both dates from params, populates vars" do
      get :index, params: {filters: {date_range: {since: "02.06.2020", until: "03.04.2021"}}}
      expect(filters.dig(:date_range, :since)).to eq "02.06.2020"
      expect(filters.dig(:date_range, :until)).to eq "03.04.2021"
    end

    it "groups by course kind" do
      course = Fabricate(:course, groups: [groups(:bottom_layer_one)], kind: event_kinds(:slk),
        maximum_participants: 20)
      course.dates.build(start_at: "02.01.2020")
      course.save
      get :index
      expect(assigns(:grouped_events).keys).to eq ["Scharleiterkurs"]
    end
  end

  context "filters per group, it" do
    let(:person) { people(:top_leader) }

    it "defaults to layer of primary group" do
      get :index
      expect(filters.dig(:groups, :ids)).to match_array(groups(:top_layer, :top_group).map(&:id))
    end

    it "can be set via param" do
      get :index, params: {filters: {groups: {ids: [groups(:bottom_layer_one).id]}}}
      expect(filters.dig(:groups, :ids)).to eq [groups(:bottom_layer_one).id.to_s]
    end

    context "finds default course offerer" do
      it "via primary group" do
        expect(person.primary_group).to eq(groups(:top_group))
        get :index
        expect(controller.params[:filters][:groups][:ids])
          .to match_array(groups(:top_layer, :top_group).map(&:id))
      end

      it "via hierarchy" do
        group = groups(:bottom_group_one_one)
        user = Fabricate(Group::BottomGroup::Leader.name.to_s, label: "foo", group: group).person
        user.update!(primary_group: nil)
        expect(user.primary_group).to be_nil
        sign_in(user)

        get :index
        expect(controller.params[:filters][:groups][:ids])
          .to match_array(groups(:bottom_layer_one).hierarchy.map(&:id))
      end
    end
  end

  context "exports to csv" do
    let(:rows) { response.body.split("\n") }
    let(:course) { Fabricate(:course, groups: [groups(:bottom_layer_one)]) }
    let(:header) do
      Regexp.new("^#{Export::Csv::UTF8_BOM}Name;Organisatoren;Kursnummer;Kursart;.*;Anzahl Anmeldungen$")
    end

    before { Fabricate(:event_date, event: course, start_at: Date.new(2020, 1, 2)) }

    context "as person without default course group, it" do
      let(:person) { people(:root) }

      it "renders csv headers" do
        get :index, format: :csv
        expect(response).to be_successful
        expect(rows.first).to match(header)
        expect(rows.size).to eq(2)
      end
    end

    context "as person with default course group, it" do
      let(:person) { people(:top_leader) }

      it "renders csv headers and filters out courses from other groups" do
        get :index, format: :csv
        expect(response).to be_successful
        expect(rows.first).to match(header)
        expect(rows.size).to eq(1)
      end
    end
  end

  context "without kind_id, it" do
    before { Event::Course.used_attributes -= [:kind_id] }

    after { Event::Course.used_attributes += [:kind_id] }

    it "groups by month" do
      course = Fabricate(:course,
        groups: [groups(:bottom_layer_one)],
        kind: event_kinds(:slk),
        maximum_participants: 20)
      course.dates.clear
      course.dates.build(start_at: "02.03.2020")
      course.save
      get :index
      expect(assigns(:grouped_events).keys).to eq(["März 2020"])
    end
  end

  context "booking info" do
    before do
      course1 = Fabricate(:course, display_booking_info: false, groups: [groups(:bottom_layer_one)])
      Fabricate(:event_date, event: course1, start_at: Date.new(2012, 1, 13))
      course2 = Fabricate(:course, display_booking_info: true, groups: [groups(:bottom_layer_one)])
      Fabricate(:event_date, event: course2, start_at: Date.new(2012, 1, 23))
    end

    it "is visible for manager" do
      sign_in(people(:top_leader))
      get :index, params: {filters: {date_range: {since: "01.01.2012", until: "01.02.2012"},
                                     groups: {ids: [groups(:bottom_layer_one).id]}}}
      expect(response.body).to have_selector("tbody tr", count: 2)
      expect(response.body).to have_selector("tbody tr:nth-child(1) td:nth-child(3)",
        text: "0 Anmeldungen")
      expect(response.body).to have_selector("tbody tr:nth-child(2) td:nth-child(3)",
        text: "0 Anmeldungen")
    end

    it "is only visible for member where allowed by course" do
      sign_in(people(:bottom_member))
      get :index, params: {filters: {date_range: {since: "01.01.2012", until: "01.02.2012"},
                                     groups: {ids: [groups(:bottom_layer_one).id]}}}
      expect(response.body).to have_selector("tbody tr", count: 2)
      expect(response.body).not_to have_selector("tbody tr:nth-child(1) td:nth-child(3)",
        text: "0 Anmeldungen")
      expect(response.body).to have_selector("tbody tr:nth-child(2) td:nth-child(3)",
        text: "0 Anmeldungen")
    end
  end
end
