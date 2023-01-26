#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe PersonResource, type: :resource do
  before { Person.delete_all }

  describe 'serialization' do
    let!(:person) { Fabricate(:person, birthday: Date.today, gender: 'm') }

    def serialized_attrs
      [
        :first_name,
        :last_name,
        :nickname,
        :company_name,
        :company,
        :email,
        :address,
        :zip_code,
        :town,
        :country,
        :gender,
        :birthday,
        :primary_group_id
      ]
    end

    def date_time_attrs
      [ :birthday ]
    end

    def read_restricted_attrs
      [ :gender, :birthday ]
    end

    it 'works' do
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(person.id)
      expect(data.jsonapi_type).to eq('people')

      (serialized_attrs - date_time_attrs).each do |attr|
        expect(data.public_send(attr)).to eq(person.public_send(attr))
      end

      date_time_attrs.each do |attr|
        expect(data.public_send(attr)).to eq(person.public_send(attr).as_json)
      end
    end

    it 'with show_details permission it includes restricted attrs' do
      set_ability { can :show_details, Person }

      render

      expect(d[0].attributes.symbolize_keys.keys).to include *read_restricted_attrs
    end

    it  'without show_details permission it does not include restricted attrs' do
      set_ability { can :read, Person }

      render

      expect(d[0].attributes.symbolize_keys.keys).not_to include *read_restricted_attrs
    end
  end

  describe 'filtering' do
    let!(:person1) { Fabricate(:person) }
    let!(:person2) { Fabricate(:person) }

    context 'by id' do
      before do
        params[:filter] = { id: { eq: person2.id } }
      end

      it 'works' do
        render
        expect(d.map(&:id)).to eq([person2.id])
      end
    end

    context 'by updated_at' do
      it 'works'
    end
  end

  describe 'sorting' do
    describe 'by id' do
      let!(:person1) { Fabricate(:person) }
      let!(:person2) { Fabricate(:person) }

      context 'when ascending' do
        before do
          params[:sort] = 'id'
        end

        it 'works' do
          render
          expect(d.map(&:id)).to eq([person1.id, person2.id].sort)
        end
      end

      context 'when descending' do
        before do
          params[:sort] = '-id'
        end

        it 'works' do
          render
          expect(d.map(&:id)).to eq([person1.id, person2.id].sort.reverse)
        end
      end
    end
  end
end
