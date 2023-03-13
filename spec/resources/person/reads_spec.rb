#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe PersonResource, type: :resource do
  before { Graphiti.context[:object] = double(can?: true) }

  describe 'sideloading' do
    before { params[:filter] = { id: person.id.to_s } }

    describe 'phone_numbers' do
      let!(:person) { Fabricate(:person) }
      let!(:phone_number1) { Fabricate(:phone_number, contactable: person) }
      let!(:phone_number2) { Fabricate(:phone_number, contactable: person) }

      before { params[:include] = 'phone_numbers' }

      it 'it works' do
        render
        phone_numbers = d[0].sideload(:phone_numbers)
        expect(phone_numbers).to have(2).items
        expect(phone_numbers.map(&:id)).to match_array [phone_number1.id, phone_number2.id]
      end
    end

    describe 'social_accounts' do
      let!(:person) { Fabricate(:person) }
      let!(:social_account1) { Fabricate(:social_account, contactable: person) }
      let!(:social_account2) { Fabricate(:social_account, contactable: person) }

      before { params[:include] = 'social_accounts' }

      it 'it works' do
        render
        social_accounts = d[0].sideload(:social_accounts)
        expect(social_accounts).to have(2).items
        expect(social_accounts.map(&:id)).to match_array [social_account1.id, social_account2.id]
      end
    end

    describe 'additional_emails' do
      let!(:person) { Fabricate(:person) }
      let!(:additional_email1) { Fabricate(:additional_email, contactable: person) }
      let!(:additional_email2) { Fabricate(:additional_email, contactable: person) }

      before { params[:include] = 'additional_emails' }

      it 'it works' do
        render
        additional_emails = d[0].sideload(:additional_emails)
        expect(additional_emails).to have(2).items
        expect(additional_emails.map(&:id)).to match_array [additional_email1.id, additional_email2.id]
      end
    end

    describe 'roles' do
      let!(:role) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)) }
      let(:person) { role.person }

      before { params[:include] = 'roles' }

      it 'it works' do
        render
        roles = d[0].sideload(:roles)
        expect(roles).to have(1).items
        expect(roles.first.id).to eq role.id
      end
    end

    describe 'primary_group' do
      let!(:person) { people(:top_leader) }

      before { params[:include] = 'primary_group' }

      it 'it works' do
        render

        primary_group_data = d[0].sideload(:primary_group)
        expect(primary_group_data.id).to eq person.primary_group_id
        expect(primary_group_data.jsonapi_type).to eq 'groups'
      end
    end

    describe 'layer_group' do
      let!(:person) { people(:bottom_member) }

      before { params[:include] = 'layer_group' }

      it 'it works' do
        render

        layer_group_data = d[0].sideload(:layer_group)
        expect(layer_group_data.id).to eq person.primary_group_id
        expect(layer_group_data.jsonapi_type).to eq 'groups'
      end

    end
  end
end
