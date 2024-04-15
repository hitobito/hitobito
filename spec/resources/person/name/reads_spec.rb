#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

describe Person::NameResource, type: :resource do

  describe 'serialization' do
    def serialized_attrs
      [
        :first_name,
        :last_name,
      ]
    end

    it 'serializes first and last name' do
      render
      data = jsonapi_data[0]
      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type] + serialized_attrs

      expect(data.id).to eq person.id
      expect(data.jsonapi_type).to eq('person-name')
    end

    it 'does not return people without roles as ability filters' do
      Role.destroy_all
      render
      expect(jsonapi_data).to be_empty
    end
  end

  describe 'filters'  do
    describe 'leads_course_id' do
      let(:course) { events(:top_course) }
      let(:leader) { event_roles(:top_leader) }

      def create_role(type, **attrs)
        person = Fabricate(:person, attrs)
        Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group), person: person)
        participation = Fabricate(:event_participation, person: person, event: course, active: true)
        "Event::Role::#{type.to_s.classify}".constantize.create(participation: participation)
      end

      before { params[:filter] = { leads_course_id: [course.id] } }

      it 'returns leader of course' do
        render
        expect(jsonapi_data).to have(1).item
        expect(jsonapi_data[0].first_name).to eq 'Bottom'
        expect(jsonapi_data[0].last_name).to eq 'Member'
      end

      it 'returns multiple leaders if they exist' do
        create_role(:leader, first_name: 'other', last_name: 'leader')
        params[:filter] = { leads_course_id: [course.id] }
        render
        expect(jsonapi_data).to have(2).items
        expect(jsonapi_data[0].first_name).to eq 'other'
        expect(jsonapi_data[0].last_name).to eq 'leader'
        expect(jsonapi_data[1].first_name).to eq 'Bottom'
        expect(jsonapi_data[1].last_name).to eq 'Member'
      end

      it 'is empty when course has no leader' do
        leader.destroy
        render
        expect(jsonapi_data).to be_empty
      end

      it 'does not treat assistant leader as leader' do
        leader.update!(type: Event::Role::AssistantLeader.sti_name)
        render
        expect(jsonapi_data).to be_empty
      end
    end
  end

end
