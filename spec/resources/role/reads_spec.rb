#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe RoleResource, type: :resource do
  before do
    allow(Graphiti.context[:object]).to receive(:can?).and_return(true)
    # set_user(people(:root))
  end

  describe 'serialization' do
    let!(:role) { roles(:bottom_member) }

    def serialized_attrs
      [:person_id, :group_id, :label, :type, :created_at, :updated_at, :deleted_at]
    end

    def date_time_attrs
      [:created_at, :updated_at, :deleted_at]
    end

    before do
      params[:filter] = { id: { eq: role.id } }
    end

    it 'works' do
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(role.id)
      expect(data.jsonapi_type).to eq('roles')

      (serialized_attrs - date_time_attrs).each do |attr|
        expect(data.public_send(attr)).to eq(role.public_send(attr))
      end

      date_time_attrs.each do |attr|
        expect(data.public_send(attr)&.to_time).to eq(role.public_send(attr))
      end
    end
  end

  describe 'sideloading' do
    let!(:role) { roles(:bottom_member) }
    before { params[:filter] = { id: role.id.to_s } }

    describe 'person' do
      before { params[:include] = 'person' }

      it 'it works' do
        render
        person_data = d[0].sideload(:person)
        expect(person_data.id).to eq role.person_id
        expect(person_data.jsonapi_type).to eq 'people'
      end
    end

    describe 'group' do
      before { params[:include] = 'group' }

      it 'it works' do
        render
        group_data = d[0].sideload(:group)
        expect(group_data.id).to eq role.group_id
        expect(group_data.jsonapi_type).to eq 'groups'
      end
    end

    describe 'layer_group' do
      before { params[:include] = 'layer_group' }

      it 'it works' do
        render
        group_data = d[0].sideload(:layer_group)
        expect(group_data.id).to eq role.group_id
        expect(group_data.jsonapi_type).to eq 'groups'
      end
    end
  end
end
