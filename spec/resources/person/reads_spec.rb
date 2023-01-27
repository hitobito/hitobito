#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe PersonResource, type: :resource do
  before { set_user(people(:root)) }

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

    before do
      params[:filter] = { id: { eq: person.id } }
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
          expect(d.map(&:id)).to eq(Person.all.pluck(:id).sort)
        end
      end

      context 'when descending' do
        before do
          params[:sort] = '-id'
        end

        it 'works' do
          render
          expect(d.map(&:id)).to eq(Person.all.pluck(:id).sort.reverse)
        end
      end
    end
  end

  describe 'sideloading' do
    describe 'phone_numbers' do
      let!(:person) { Fabricate(:person) }
      let!(:phone_number1) { Fabricate(:phone_number, contactable: person) }
      let!(:phone_number2) { Fabricate(:phone_number, contactable: person) }

      before do
        params[:filter] = { id: person.id.to_s }
        params[:include] = 'phone_numbers'
      end

      it 'it works with show_details permission' do

        set_user(people(:root))

        render

        phone_numbers = d[0].relationships.dig(:phone_numbers, :data)
        expect(phone_numbers).to have(2).items

        phone_numbers in [
          {type: "phone_numbers", id: first_id},
          {type: "phone_numbers", id: second_id}
        ]
        expect([first_id, second_id]).to match_array [phone_number1.id.to_s, phone_number2.id.to_s]
      end

      it  'it does not work without show_details permission' do
        set_ability { }

        render

        expect(d[0].sideload(:phone_numbers)).to eq []
      end
    end

    describe 'social_accounts' do
      let!(:person) { Fabricate(:person) }
      let!(:social_account1) { Fabricate(:social_account, contactable: person) }
      let!(:social_account2) { Fabricate(:social_account, contactable: person) }

      before do
        params[:filter] = { id: person.id.to_s }
        params[:include] = 'social_accounts'
      end

      it 'it works with show_details permission' do
        set_user(people(:root))

        render

        social_accounts = d[0].relationships.dig(:social_accounts, :data)
        expect(social_accounts).to have(2).items

        social_accounts in [
          {type: "social_accounts", id: first_id},
          {type: "social_accounts", id: second_id}
        ]
        expect([first_id, second_id]).to match_array [social_account1.id.to_s, social_account2.id.to_s]
      end

      it  'it does not work without show_details permission' do
        set_ability { }

        render

        expect(d[0].sideload(:social_accounts)).to eq []
      end
    end

    describe 'additional_emails' do
      let!(:person) { Fabricate(:person) }
      let!(:additional_email1) { Fabricate(:additional_email, contactable: person) }
      let!(:additional_email2) { Fabricate(:additional_email, contactable: person) }

      before do
        params[:filter] = { id: person.id.to_s }
        params[:include] = 'additional_emails'
      end

      it 'it works with show_details permission' do

        set_user(people(:root))

        render

        additional_emails = d[0].relationships.dig(:additional_emails, :data)
        expect(additional_emails).to have(2).items

        additional_emails in [
          {type: "additional_emails", id: first_id},
          {type: "additional_emails", id: second_id}
        ]
        expect([first_id, second_id]).to match_array [additional_email1.id.to_s, additional_email2.id.to_s]
      end

      it  'it does not work without show_details permission' do
        set_ability { }

        render

        expect(d[0].sideload(:additional_emails)).to eq []
      end
    end
  end
end
