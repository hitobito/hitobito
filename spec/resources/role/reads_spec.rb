#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require "spec_helper"

describe RoleResource, type: :resource do
  let!(:role) { roles(:bottom_member) }
  let(:person) { user_role.person }

  describe "serialization" do
    def serialized_attrs
      [:person_id, :group_id, :label, :type, :created_at, :updated_at, :start_on, :end_on]
    end

    def date_time_attrs
      [:created_at, :updated_at]
    end

    def computed_attrs
      {name: ->(role) { role.class.model_name.human }}
    end

    before { params[:filter] = {id: {eq: role.id}} }

    context "without appropriate permission" do
      let(:person) { Fabricate(:person) }

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context "with appropriate permission" do
      let(:person) { Fabricate(Group::BottomLayer::Leader.name, group: role.group).person }

      it "works" do
        render
        data = jsonapi_data[0]

        expect(data.attributes.symbolize_keys.keys).to match_array [:id,
          :jsonapi_type] + serialized_attrs + computed_attrs.keys

        expect(data.id).to eq(role.id)
        expect(data.jsonapi_type).to eq("roles")

        (serialized_attrs - date_time_attrs).each do |attr|
          expect(data.public_send(attr)).to eq(role.public_send(attr))
        end

        date_time_attrs.each do |attr|
          data_time, role_time = data.public_send(attr)&.to_time, role.public_send(attr)

          # when time is nil, it should equal nil, if not, it should be equal within 1 second
          if data_time.nil? || role_time.nil?
            expect(data_time).to eq(role_time)
          else
            expect(data_time).to be_within(1.second).of(role_time)
          end
        end

        computed_attrs.each do |attr, attr_definition|
          expect(data.public_send(attr)).to eq(attr_definition.call(role))
        end
      end
    end
  end

  describe "sideloading" do
    before { params[:filter] = {id: role.id.to_s} }

    describe "person" do
      before { params[:include] = "person" }

      context "without appropriate permission" do
        let(:person) { Fabricate(:person) }

        it "does not expose data" do
          render
          expect(jsonapi_data).to eq([])
        end
      end

      context "with appropriate permission" do
        let(:person) { Fabricate(Group::BottomLayer::Leader.name, group: role.group).person }

        it "it works" do
          render
          person_data = d[0].sideload(:person)
          expect(person_data.id).to eq role.person_id
          expect(person_data.jsonapi_type).to eq "people"
        end
      end
    end

    describe "group" do
      before { params[:include] = "group" }

      context "without appropriate permission" do
        let(:person) { Fabricate(:person) }

        it "does not expose data" do
          render
          expect(jsonapi_data).to eq([])
        end
      end

      context "with appropriate permission" do
        let(:person) { Fabricate(Group::BottomLayer::Leader.name, group: role.group).person }

        it "it works" do
          render
          group_data = d[0].sideload(:group)
          expect(group_data.id).to eq role.group_id
          expect(group_data.jsonapi_type).to eq "groups"
        end
      end
    end

    describe "layer_group" do
      before { params[:include] = "layer_group" }

      context "without appropriate permission" do
        let(:person) { Fabricate(:person) }

        it "does not expose data" do
          render
          expect(jsonapi_data).to eq([])
        end
      end

      context "with appropriate permission" do
        let(:person) { Fabricate(Group::BottomLayer::Leader.name, group: role.group).person }

        it "it works" do
          render
          group_data = d[0].sideload(:layer_group)
          expect(group_data.id).to eq role.group_id
          expect(group_data.jsonapi_type).to eq "groups"
        end
      end
    end
  end

  describe "filtering" do
    describe "active_at" do
      let(:person) { Fabricate(Group::BottomLayer::Leader.name, group: role.group).person }
      let!(:new_role) { Fabricate(Group::BottomLayer::Leader.name, group: role.group, start_on: 1.week.ago) }
      let!(:past_role) {
        Fabricate(Group::BottomLayer::Leader.name, group: role.group, start_on: 1.year.ago, end_on: 1.week.ago)
      }
      let!(:past_role_of_readable_person) {
        Fabricate(Group::BottomLayer::Leader.name, group: role.group, start_on: 1.year.ago, end_on: 1.week.ago,
          person: new_role.person)
      }
      let!(:future_role) { Fabricate(Group::BottomLayer::Leader.name, group: role.group, start_on: 1.week.from_now) }
      let!(:future_role_of_readable_person) {
        Fabricate(Group::BottomLayer::Leader.name, group: role.group, start_on: 1.week.from_now,
          person: new_role.person)
      }

      context "without filter" do
        before { params[:filter] = {} }

        it "filters by active roles" do
          render
          expect(jsonapi_data.map(&:id)).to include(role.id)
          expect(jsonapi_data.map(&:id)).to include(new_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role_of_readable_person.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role_of_readable_person.id)
        end
      end

      context "without parameter" do
        before { params[:filter] = {active: nil} }

        it "works" do
          render
          expect(jsonapi_data.map(&:id)).to include(role.id)
          expect(jsonapi_data.map(&:id)).to include(new_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role_of_readable_person.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role_of_readable_person.id)
        end
      end

      context "with parameter in the past" do
        before { params[:filter] = {active: 2.weeks.ago.to_date} }

        it "filters away new role but does not expose past role of inaccessible person" do
          render
          expect(jsonapi_data.map(&:id)).to include(role.id)
          expect(jsonapi_data.map(&:id)).not_to include(new_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role.id)
          expect(jsonapi_data.map(&:id)).to include(past_role_of_readable_person.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role_of_readable_person.id)
        end
      end

      context "with parameter in the future" do
        before { params[:filter] = {active: 2.weeks.from_now.to_date} }

        it "includes future role of accessible person" do
          render
          expect(jsonapi_data.map(&:id)).to include(role.id)
          expect(jsonapi_data.map(&:id)).to include(new_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role.id)
          expect(jsonapi_data.map(&:id)).not_to include(past_role_of_readable_person.id)
          expect(jsonapi_data.map(&:id)).not_to include(future_role.id)
          expect(jsonapi_data.map(&:id)).to include(future_role_of_readable_person.id)
        end
      end
    end
  end
end
