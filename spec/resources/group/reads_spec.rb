#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe GroupResource, type: :resource do
  # before do
  #   set_user(people(:root))
  #   allow_any_instance_of(described_class).to receive(:index_ability, &:current_ability)
  # end

  describe 'serialization' do
    let!(:group) { groups(:bottom_group_two_one) }

    def serialized_attrs
      [
        :name,
        :short_name,
        :display_name,
        :type,
        :layer,
        :email,
        :address,
        :zip_code,
        :town,
        :country,
        :created_at,
        :updated_at,
        :deleted_at
      ]
    end

    def date_time_attrs
      [
        :created_at,
        :updated_at,
        :deleted_at
      ]
    end

    before do
      params[:filter] = { id: { eq: group.id } }
    end

    it 'works' do
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(group.id)
      expect(data.jsonapi_type).to eq('groups')

      (serialized_attrs - date_time_attrs).each do |attr|
        expect(data.public_send(attr)).to eq(group.public_send(attr))
      end

      date_time_attrs.each do |attr|
        expect(data.public_send(attr)&.to_time).to eq(group.public_send(attr))
      end
    end
  end

  describe 'sideloading' do
    let!(:group) { groups(:bottom_group_one_one_one) }

    before { params[:filter] = { id: group.id.to_s } }

    describe 'parent' do
      before { params[:include] = 'parent' }

      it 'it works' do
        render

        parent_data = d[0].sideload(:parent)

        expect(parent_data.id).to eq(group.parent_id)
        expect(parent_data.jsonapi_type).to eq('groups')
      end
    end

    describe 'layer_group' do
      before { params[:include] = 'layer_group' }

      it 'it works' do
        # make sure our test subject has a layer_group that is not its direct parent
        expect(group.parent_id).not_to eq group.layer_group_id

        render

        layer_group_data = d[0].sideload(:layer_group)

        expect(layer_group_data.id).to eq(group.layer_group_id)
        expect(layer_group_data.jsonapi_type).to eq('groups')
      end
    end
  end
end
