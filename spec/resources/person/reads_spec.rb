#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

describe PersonResource, type: :resource do
  let(:user) { user_role.person }
  let(:ability) { Ability.new(user) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer_one) { groups(:bottom_layer_one) }

  describe 'serialization' do
    let!(:person) { Fabricate(:person, birthday: Date.today, gender: 'm') }
    let!(:role) { Fabricate(Group::BottomLayer::Member.name, person: person, group: bottom_layer_one) }

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
        :language,
        :primary_group_id
      ]
    end

    def date_time_attrs
      [:birthday]
    end

    def read_restricted_attrs
      [:gender, :birthday]
    end

    before do
      params[:filter] = { id: { eq: person.id } }
    end

    context 'without appropriate permission' do
      let(:user) { Fabricate(:person) }

      it 'does not expose data' do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context 'with appropriate permission' do
      let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: role.group) }

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
    end

    context 'with show_details permission, it' do
      let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: role.group) }
      it 'includes restricted attrs' do
        render

        expect(d[0].attributes.symbolize_keys.keys).to include *read_restricted_attrs
      end
    end

    context 'without show_details permission, it' do
      # Both have contact_data, so they can see each other, but not each other's details
      let!(:role) { Fabricate(Group::BottomLayer::Leader.name, person: person, group: bottom_layer_one) }
      let!(:user_role) { Fabricate(Group::TopGroup::Member.name, group: top_group) }
      it 'does not include restricted attrs' do
        render

        expect(d[0].attributes.symbolize_keys.keys).not_to include *read_restricted_attrs
      end
    end

    context 'with person language' do
      let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: role.group) }

      context 'enabled' do
        it 'includes language' do
          render

          data = jsonapi_data[0]

          expect(data.id).to eq(person.id)
          expect(data.jsonapi_type).to eq('people')

          expect(data.attributes.symbolize_keys.keys).to include(:language)
          expect(data.language).to eq('de')
        end
      end

      # This is currently skipped since the FeatureGate that we're trying to mock is being done when loading the constant.
      # As seen in the before block, we're trying to remove the language attribute from the attributes and then reload the constant
      # that seemingly still does not get this spec to work though
      context 'disabled', :skip do
        before do
          expect_any_instance_of(FeatureGate).to receive(:person_language_enabled?).and_return(false)

          PersonResource.config[:attributes].delete(:language)
          load 'app/resources/person_resource.rb'
        end

        it 'does not include language' do
          render

          data = jsonapi_data[0]

          expect(data.id).to eq(person.id)
          expect(data.jsonapi_type).to eq('people')

          expect(data.attributes.symbolize_keys.keys).to_not include(:language)
        end
      end
    end
  end

  describe 'filtering' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let!(:role1) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let!(:role2) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let(:person1) { role1.person }
    let(:person2) { role2.person }

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
      before do
        person1.update_attribute(:updated_at, 1.minute.ago)
        person2.update_attribute(:updated_at, 1.day.ago)
        params[:filter] = { updated_at: { gt: 1.hour.ago.to_s } }
      end

      it 'works' do
        render
        expect(d.map(&:id)).to include(person1.id)
        expect(d.map(&:id)).not_to include(person2.id)
      end
    end
  end

  describe 'sorting' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let!(:role1) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let!(:role2) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let(:person1) { role1.person }
    let(:person2) { role2.person }

    describe 'by id' do
      context 'when ascending' do
        before do
          params[:sort] = 'id'
        end

        it 'works' do
          render
          ids = d.map(&:id)
          expect(ids).to be_present
          expect(ids).to eq(ids.sort)
        end
      end

      context 'when descending' do
        before do
          params[:sort] = '-id'
        end

        it 'works' do
          render
          ids = d.map(&:id)
          expect(ids).to be_present
          expect(ids).to eq(ids.sort.reverse)
        end
      end
    end
  end

  describe 'sideloading' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: bottom_layer_one) }
    let(:role) { roles(:bottom_member) }
    let!(:person) { role.person }

    before { params[:filter] = { id: person.id.to_s } }

    describe 'phone_numbers' do
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
      before { params[:include] = 'roles' }

      it 'it works' do
        render
        roles = d[0].sideload(:roles)
        expect(roles).to have(1).items
        expect(roles.first.id).to eq role.id
      end
    end

    describe 'primary_group' do
      before { params[:include] = 'primary_group' }

      it 'it works' do
        render

        primary_group_data = d[0].sideload(:primary_group)
        expect(primary_group_data.id).to eq person.primary_group_id
        expect(primary_group_data.jsonapi_type).to eq 'groups'
      end
    end

    describe 'layer_group' do
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
