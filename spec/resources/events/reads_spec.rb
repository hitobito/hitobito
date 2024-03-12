# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe EventResource, type: :resource do
  let(:event) { events(:top_event) }
  let(:course) { events(:top_course) }

  describe 'serialization' do
    let(:serialized_attrs) do
      [
        :applicant_count,
        :application_closing_at,
        :application_contact_id,
        :application_opening_at,
        :name,
        :cost,
        :created_at,
        :dates,
        :group_ids,
        :kind_id,
        :location,
        :maximum_participants,
        :motto,
        :number,
        :participant_count,
        :state,
        :type,
        :updated_at
      ]
    end

    it 'works' do
      params[:filter] = { id: { eq: event.id } }
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id,
                                                                  :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(event.id)
      expect(data.jsonapi_type).to eq('events')
      expect(data.attributes['type']).to be_blank
    end

    it 'serializes dates in iso8601 format' do
      course.dates.update_all('finish_at = start_at')
      params[:filter] = { id: { eq: course.id } }
      render
      date = jsonapi_data[0].attributes['dates'].first
      expect(date.keys).to match_array %w(label start_at finish_at location)
      expect(date['start_at']).to eq "2012-03-01T00:00:00+01:00"
      expect(date['finish_at']).to eq "2012-03-01T00:00:00+01:00"
    end
  end

  describe 'filtering' do
    let(:group) { groups(:top_group) }

    describe 'by kind_id' do
      it 'returns only event matching kind id' do
        params[:filter] = { kind_id: event_kinds(:slk).id }
        render
        expect(jsonapi_data).to have(1).items
      end
    end

    describe 'by updated_at' do
      it 'returns only event matching kind id' do
        course.update_columns(updated_at: 1.week.ago)
        event.update_columns(updated_at: 1.day.ago)
        params[:filter] = { updated_at: { gte: 2.days.ago.to_date.to_s } }
        render
        expect(jsonapi_data).to have(1).items
        expect(jsonapi_data[0].id).to eq event.id
      end
    end

    describe 'by type' do
      it 'includes exact type' do
        params[:filter] = { type: 'Event::Course' }
        render
        expect(jsonapi_data).to have(1).item
        expect(jsonapi_data[0].id).to eq course.id
      end

      it 'treats "null" vale as nil type' do
        params[:filter] = { type: 'null' }
        render
        expect(jsonapi_data).to have(1).item
        expect(jsonapi_data[0].id).to eq event.id
      end

      it 'can combine filters' do
        params[:filter] = { type: 'null,Event::Course' }
        render
        expect(jsonapi_data).to have(2).items
      end
    end

    describe 'by group_id' do
      let(:top_layer) { groups(:top_layer) }
      let(:top_group) { groups(:top_group) }
      let!(:other) { Fabricate(:event, groups: [groups(:top_group)]) }

      it 'returns only events matching group_ids' do
        params[:filter] = { group_id: top_group.id }
        render
        expect(jsonapi_data).to have(1).items
      end

      it 'returns all if multiple matches' do
        params[:filter] = { group_id: [top_group.id, top_layer.id] }
        render
        expect(jsonapi_data).to have(3).items
      end
    end

    describe 'by before_or_on' do
      it 'filters using Event::before_or_on' do
        event.dates.first.update(start_at: '2012-02-28')
        params[:filter] = { before_or_on: '2012-02-28' }
        expect(Event).to receive(:before_or_on).with(Date.new(2012, 2, 28)).and_call_original
        render
        expect(jsonapi_data).to have(1).item
        expect(jsonapi_data[0].id).to eq event.id
      end
    end

    describe 'by after_or_on' do
      it 'filters using Event::after_or_on' do
        event.dates.first.update(start_at: '2012-03-5')
        params[:filter] = { after_or_on: '2012-03-02' }
        expect(Event).to receive(:after_or_on).with(Date.new(2012, 3, 2)).and_call_original
        render
        expect(jsonapi_data).to have(1).item
        expect(jsonapi_data[0].id).to eq event.id
      end
    end
  end
end
