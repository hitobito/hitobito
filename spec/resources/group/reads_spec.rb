#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

describe GroupResource, type: :resource do
  include Rails.application.routes.url_helpers

  describe 'serialization' do
    let!(:group) { groups(:bottom_group_two_one) }
    before { group.update!(self_registration_role_type: Group::BottomGroup::Member.sti_name) }

    def serialized_attrs
      [
        :name,
        :short_name,
        :display_name,
        :description,
        :type,
        :layer,
        :email,
        :address,
        :zip_code,
        :town,
        :country,
        :require_person_add_requests,
        :self_registration_url,
        :archived_at,
        :created_at,
        :updated_at,
        :deleted_at
      ]
    end

    def date_time_attrs
      [
        :archived_at,
        :created_at,
        :updated_at,
        :deleted_at
      ]
    end


    before do
      params[:filter] = { id: { eq: group.id } }
    end

    def read_attr(attr)
      return group.public_send(attr) unless attr.match(/self_registration_url/)

      group_self_registration_url(group)
    end

    it 'works' do
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(group.id)
      expect(data.jsonapi_type).to eq('groups')

      (serialized_attrs - date_time_attrs).each do |attr|
        expect(data.public_send(attr)).to eq(read_attr(attr))
      end

      date_time_attrs.each do |attr|
        expect(data.public_send(attr)&.to_time).to eq(group.public_send(attr))
      end
    end

    describe 'attribute self_registration_url' do
      it 'is present if group.self_registration_active?' do
        allow_any_instance_of(Group).to receive(:self_registration_active?).and_return(true)
        render

        expect(jsonapi_data[0]['self_registration_url']).to eq(group_self_registration_url(group))
      end

      it 'is blank if group.self_registration_active? is false' do
        allow_any_instance_of(Group).to receive(:self_registration_active?).and_return(false)
        render

        expect(jsonapi_data[0]['self_registration_url']).to be_blank
      end
    end

    describe 'optional logo attributes' do
      before { params[:extra_fields] = { groups: 'logo' } }

      it 'includes active_storage path to logo' do
        group.logo.attach(
          io: File.open('spec/fixtures/person/test_picture.jpg'),
          filename: 'test_picture.jpg'
        )
        allow(context).to receive(:rails_storage_proxy_url).and_return('/active_storage')
        render
        expect(jsonapi_data[0]['logo']).to eq('/active_storage')
      end

      it 'is blank if no logo is set' do
        render
        expect(jsonapi_data[0]['logo']).to be_blank
      end
    end
  end

  describe 'filtering' do
    let(:group) { groups(:top_group) }

    it 'can filter by type' do
      params[:filter] = { type: 'Group::TopGroup' }
      render
      expect(d).to have(1).item
    end

    it 'excludes archived group by default' do
      group.update_columns(archived_at: Time.zone.now)
      params[:filter] = { type: 'Group::TopGroup' }
      render
      expect(d).to be_empty
    end

    context 'by with_archived' do
      before { group.update_columns(archived_at: Time.zone.now) }

      it 'when true it includes archived groups' do
        params[:filter] = { type: 'Group::TopGroup', with_archived: true }
        render
        expect(d).to have(1).item
      end

      it 'when false it excludes archived groups' do
        params[:filter] = { type: 'Group::TopGroup', with_archived: false }
        render
        expect(d).to be_empty
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

    [:creator, :contact, :updater, :deleter].each do |assoc|
      it "includes #{assoc} if asked to do so" do
        group.update_columns("#{assoc}_id" => person.id)
        expect(group.send(assoc)).to be_present
        params[:include] = assoc

        render

        person_attrs = d[0].sideload(assoc)
        expect(person_attrs).to be_present
      end
    end
  end
end
