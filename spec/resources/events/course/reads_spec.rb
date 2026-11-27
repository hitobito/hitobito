# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::CourseResource, type: :resource do
  include Rails.application.routes.url_helpers
  let(:course) { events(:top_course) }

  describe "availability" do
    before { params[:filter] = {id: {eq: course.id}} }

    it "reports free places" do
      course.update_columns(maximum_participants: 2, participant_count: 1, waiting_list: false)
      render
      expect(jsonapi_data[0].attributes).to include("places_available" => true,
        "waiting_list_available" => false)
    end

    it "reports a full course with waiting list" do
      course.update_columns(maximum_participants: 1, participant_count: 1, waiting_list: true)
      render
      expect(jsonapi_data[0].attributes).to include("places_available" => false,
        "waiting_list_available" => true)
    end

    context "external application" do
      before do
        course.update_columns(external_applications: true, application_opening_at: nil,
          application_closing_at: nil, maximum_participants: nil)
      end

      it "is possible for an open course" do
        render
        expect(jsonapi_data[0].attributes["external_application_possible"]).to be true
      end

      it "is not possible without external applications" do
        course.update_columns(external_applications: false)
        render
        expect(jsonapi_data[0].attributes["external_application_possible"]).to be false
      end

      it "is not possible for a full course without waiting list" do
        course.update_columns(maximum_participants: 1, participant_count: 1, waiting_list: false)
        render
        expect(jsonapi_data[0].attributes["external_application_possible"]).to be false
      end
    end
  end

  describe "serialization" do
    before do
      params[:filter] = {id: {eq: course.id}}
    end

    let(:serialized_attrs) do
      [
        :applicant_count,
        :application_closing_at,
        :application_contact_id,
        :application_opening_at,
        :application_conditions,
        :cost,
        :created_at,
        :description,
        :description_html,
        :display_booking_info,
        :external_applications,
        :external_application_link,
        :group_ids,
        :kind_id,
        :location,
        :maximum_participants,
        :required_contact_attrs,
        :hidden_contact_attrs,
        :places_available,
        :waiting_list_available,
        :external_application_possible,
        :minimum_participants,
        :motto,
        :name,
        :number,
        :participant_count,
        :participations_visible,
        :teamer_count,
        :training_days,
        :type,
        :state,
        :updated_at
      ]
    end

    it "works" do
      render
      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id,
        :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(course.id)
      expect(data.jsonapi_type).to eq("courses")
      expect(data.attributes["type"]).to eq "Event::Course"
    end

    describe "leaders" do
      let(:person) { people(:root) }

      def create_role(type, **attrs)
        person = Fabricate(:person, attrs)
        participation = Fabricate(:event_participation, participant: person, event: course, active: true)
        "Event::Role::#{type.to_s.classify}".constantize.create!(participation: participation)
      end

      it "is empty when no leaders are present" do
        event_roles(:top_leader).destroy!
        params[:include] = "leaders"

        render

        leaders = d[0].sideload(:leaders)
        expect(leaders).to be_nil
      end

      it "contains only leader roles" do
        create_role(:leader, first_name: "second leader", last_name: nil)
        create_role(:cook)
        params[:include] = "leaders"

        render

        leaders = d[0].sideload(:leaders).map(&:first_name)
        expect(leaders).to match_array [
          "Bottom",
          "second leader"
        ]
      end
    end
  end

  describe "filtering" do
    describe "by number" do
      let!(:one) { Fabricate(:course, number: "COURSE-123") }
      let!(:two) { Fabricate(:course, number: "COURSE-456") }

      it "returns only courses with equal number" do
        params[:filter] = {number: course.number}
        render
        expect(jsonapi_data).to have(1).items
      end

      it "returns only courses with number having a specific prefix" do
        params[:filter] = {number: {prefix: "COURSE-"}}
        render
        expect(jsonapi_data).to have(2).items
      end
    end
  end

  describe "including" do
    it "may include leaders" do
      params[:include] = "leaders"
      render
      leaders = d[0].sideload(:leaders)
      expect(leaders[0].id).to eq people(:bottom_member).id
      expect(leaders[0].first_name).to eq "Bottom"
      expect(leaders[0].last_name).to eq "Member"
    end
  end
end
