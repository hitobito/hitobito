# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe JsonApi::PeopleController, type: [:request] do
  # reset locale back to :de for other specs
  after { I18n.locale = :de }

  let(:params) { {} }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  let(:person_attrs) {
    %w(first_name last_name nickname company_name company
       email address zip_code town country gender birthday primary_group_id)
  }

  let(:show_details_attrs) {
    %w(gender birthday)
  }

  describe 'GET #index' do
    context 'unauthorized' do
      it 'returns 401' do
        jsonapi_get '/api/people', params: params

        expect(response).to have_http_status(401)

         errors = jsonapi_errors

         expect(errors.first.status).to eq('401')
         expect(errors.first.title).to eq('Login required')
         expect(errors.first.detail).to eq('You need to login before accessing this resource.')
      end
    end

    context 'with service token' do
      context 'authorized' do
        let(:permitted_service_token) { service_tokens(:permitted_top_layer_token) }
        let(:params) { { token: permitted_service_token.token } }

        it 'returns all people with roles for top_layer token with layer_and_below_read permission' do
          Fabricate(:role, type: 'Group::BottomLayer::Leader', group: groups(:bottom_layer_two))

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'only returns values for given field list' do
          selected_attrs = %w(first_name zip_code)
          params[:fields] = { people: selected_attrs }

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          selected_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end

          (person_attrs - selected_attrs).each do |attr|
            expect(person.has_key?(attr)).to eq(false)
          end
        end

        it 'returns only people from token`s layer with layer_read permission' do
          permitted_service_token.update!(layer_and_below_read: false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(1)

          person = d.first

          expect(person.id).to eq(top_leader.id)
        end

        it 'returns people filtered/ordered by updated_at' do
          Person.update_all(updated_at: 10.seconds.ago)
          Fabricate(:role, type: 'Group::BottomLayer::Leader', group: groups(:bottom_layer_two)).person
          bottom_member.touch

          jsonapi_get '/api/people', params: params.merge(filter: { updated_at: 5.seconds.ago })

          expect(response).to have_http_status(200)
          expect(d.size).to eq(2)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'returns people with contactable relations' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.find { |p| p.id == contactable_person.id }

          expect(person.relationships.size).to eq(3)
          expect(person.relationships.keys).to match_array(['phone_numbers', 'social_accounts', 'additional_emails'])
        end

        it 'includes contactables based on params' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers')

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          expect(included.size).to eq(1)
          phone_number_json = included.first
          phone_number_record = contactable_person.phone_numbers.first

          expect(phone_number_json.jsonapi_type).to eq('phone_numbers')

          phone_number_record.attributes.each do |attr, expected|
            expect(phone_number_json.has_key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil
          
          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(['phone_numbers', 'additional_emails'])
        end

        it 'returns 403 if token has no people permission' do
          permitted_service_token.update!(people: false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(403)

           errors = jsonapi_errors

           expect(errors.first.status).to eq('403')
           expect(errors.first.title).to eq('Access denied')
           expect(errors.first.detail).to eq('You are not allowed to access this resource.')
        end
      end
    end

    context 'with signed in user session' do
      context 'authorized' do
        before do
          sign_in(top_leader)
          # mock check for user since sign_in devise helper is not setting any cookies
          allow_any_instance_of(described_class)
            .to receive(:user_session?).and_return(true)
        end

        it 'returns all people with roles' do
          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(2)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'returns people with contactable relations' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.find { |p| p.id == contactable_person.id }

          expect(person.relationships.size).to eq(3)
          expect(person.relationships.keys).to match_array(['phone_numbers', 'social_accounts', 'additional_emails'])
        end

        it 'includes contactables based on params' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers')

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          expect(included.size).to eq(1)
          phone_number_json = included.first
          phone_number_record = contactable_person.phone_numbers.first

          expect(phone_number_json.jsonapi_type).to eq('phone_numbers')

          phone_number_record.attributes.each do |attr, expected|
            expect(phone_number_json.has_key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil
          
          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(['phone_numbers', 'additional_emails'])
        end

        it 'returns people filtered/ordered by updated_at' do
          top_leader.update(updated_at: 10.seconds.ago)
          bottom_member.touch

          jsonapi_get '/api/people', params: params.merge(filter: { updated_at: 5.seconds.ago })

          expect(response).to have_http_status(200)
          expect(d.size).to eq(1)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'hides certain attributes and relations when show_details is not given' do
          allow_any_instance_of(PersonResource).to receive(:show_details?).and_return(false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(2)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          show_details_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(false)
          end

        end
      end
    end

    context 'with personal oauth access token' do
      context 'authorized' do
        let(:token) { Fabricate(:access_token, resource_owner_id: top_leader.id) }

        before do
          allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { token }
          allow(token).to receive(:acceptable?) { true }
          allow(token).to receive(:accessible?) { true }
        end

        it 'returns all people with roles' do
          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(2)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'returns only readable people' do
        end

        it 'returns people with contactable relations' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.find { |p| p.id == contactable_person.id }

          expect(person.relationships.size).to eq(3)
          expect(person.relationships.keys).to match_array(['phone_numbers', 'social_accounts', 'additional_emails'])
        end

        it 'includes contactables based on params' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers')

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          expect(included.size).to eq(1)
          phone_number_json = included.first
          phone_number_record = contactable_person.phone_numbers.first

          expect(phone_number_json.jsonapi_type).to eq('phone_numbers')

          phone_number_record.attributes.each do |attr, expected|
            expect(phone_number_json.has_key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil
          
          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(['phone_numbers', 'additional_emails'])
        end

        it 'returns people filtered/ordered by updated_at' do
          top_leader.update(updated_at: 10.seconds.ago)
          bottom_member.touch

          jsonapi_get '/api/people', params: params.merge(filter: { updated_at: 5.seconds.ago })

          expect(response).to have_http_status(200)
          expect(d.size).to eq(1)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'hides certain attributes and relations when show_details is not given' do
          allow_any_instance_of(PersonResource).to receive(:show_details?).and_return(false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(2)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          show_details_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(false)
          end

        end
      end
    end
  end

  describe 'GET #show' do
    context 'unauthorized' do
      it 'returns 401 for existing person id' do
        jsonapi_get "/api/people/#{top_leader.id}", params: params

        expect(response).to have_http_status(401)
      end

      it 'returns 401 for non existing person' do
        jsonapi_get "/api/people/#{Person.maximum(:id).succ}", params: params

        expect(response).to have_http_status(401)
      end
    end

    context 'with service token' do
      context 'authorized' do
        let(:permitted_service_token) { service_tokens(:permitted_top_layer_token) }
        let(:params) { { token: permitted_service_token.token } }

        it 'returns 404 for non existing person' do
          jsonapi_get "/api/people/#{Person.maximum(:id).succ}", params: params

          expect(response).to have_http_status(404)
        end

        it 'returns person with lower roles for top_layer token with layer_and_below_read permission' do
          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(200)

          person = d

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'only returns values for given field list' do
          selected_attrs = %w(first_name zip_code)
          params[:fields] = { people: selected_attrs }

          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(200)

          person = d

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          selected_attrs.each do |attr|
            expect(person.has_key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end

          (person_attrs - selected_attrs).each do |attr|
            expect(person.has_key?(attr)).to eq(false)
          end
        end

        it 'returns 403 for person with lower roles using token with layer_read permission' do
          permitted_service_token.update!(layer_and_below_read: false)

          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Access denied')
          expect(errors.first.detail).to eq('You are not allowed to access this resource.')
        end

        it 'returns 403 in german if locale param set' do
          permitted_service_token.update!(layer_and_below_read: false)
          params[:locale] = :de

          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Access denied')
          expect(errors.first.detail).to eq('Du bist nicht berechtigt auf diese Resource zuzugreifen.')
        end

        it 'returns person from token`s layer with layer_read permission' do
          person = Fabricate(Group::TopLayer::TopAdmin.to_s, group: groups(:top_layer)).person

          permitted_service_token.update!(layer_and_below_read: false)

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
        end

        it 'returns person with contactable relations' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params

          expect(response).to have_http_status(200)

          person = d

          expect(person.relationships.size).to eq(3)
          expect(person.relationships.keys).to match_array(['phone_numbers', 'social_accounts', 'additional_emails'])
        end

        it 'includes contactables based on params' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers')

          expect(response).to have_http_status(200)

          expect(included.size).to eq(1)
          phone_number_json = included.first
          phone_number_record = contactable_person.phone_numbers.first

          expect(phone_number_json.jsonapi_type).to eq('phone_numbers')

          phone_number_record.attributes.each do |attr, expected|
            expect(phone_number_json.has_key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil
          
          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(['phone_numbers', 'additional_emails'])
        end

        it 'returns 404 if token has no people permission' do
          permitted_service_token.update!(people: false)

          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'with signed in user session' do
      context 'authorized' do
        before do
          sign_in(bottom_member)
          # mock check for user since sign_in devise helper is not setting any cookies
          allow_any_instance_of(described_class)
            .to receive(:user_session?).and_return(true)
        end

        it 'returns 404 for non existing person' do
          jsonapi_get "/api/people/#{Person.maximum(:id).succ}", params: params

          expect(response).to have_http_status(404)
        end

        it 'returns 403 for person without access' do
          jsonapi_get "/api/people/#{top_leader.id}", params: params

          expect(response).to have_http_status(403)
        end

        it 'returns person with access' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
          expect(d.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(d.has_key?(attr)).to eq(true)

            expect(d.send(attr.to_sym)).to eq(person.send(attr.to_sym))
          end
        end

        it 'returns people with contactable relations' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_one),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.relationships.size).to eq(3)
          expect(d.relationships.keys).to match_array(['phone_numbers', 'social_accounts', 'additional_emails'])
        end

        it 'includes contactables based on params' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_one),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers')

          expect(response).to have_http_status(200)

          expect(included.size).to eq(1)
          phone_number_json = included.first
          phone_number_record = contactable_person.phone_numbers.first

          expect(phone_number_json.jsonapi_type).to eq('phone_numbers')

          phone_number_record.attributes.each do |attr, expected|
            expect(phone_number_json.has_key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil
          
          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(['phone_numbers', 'additional_emails'])
        end

        it 'hides certain attributes and relations when show_details is not given' do
          allow_any_instance_of(PersonResource).to receive(:show_details?).and_return(false)

          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
          expect(d.jsonapi_type).to eq('people')

          show_details_attrs.each do |attr|
            expect(d.has_key?(attr)).to eq(false)
          end

        end
      end
    end

    context 'with personal oauth access token' do
      context 'authorized' do
        let(:token) { Fabricate(:access_token, resource_owner_id: bottom_member.id) }

        before do
          allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { token }
          allow(token).to receive(:acceptable?) { true }
          allow(token).to receive(:accessible?) { true }
        end

        it 'returns 404 for non existing person' do
          jsonapi_get "/api/people/#{Person.maximum(:id).succ}", params: params

          expect(response).to have_http_status(404)
        end

        it 'returns 403 for person without access' do
          jsonapi_get "/api/people/#{top_leader.id}", params: params

          expect(response).to have_http_status(403)
        end

        it 'returns person with access' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
          expect(d.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(d.has_key?(attr)).to eq(true)

            expect(d.send(attr.to_sym)).to eq(person.send(attr.to_sym))
          end
        end

        it 'returns people with contactable relations' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_one),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.relationships.size).to eq(3)
          expect(d.relationships.keys).to match_array(['phone_numbers', 'social_accounts', 'additional_emails'])
        end

        it 'includes contactables based on params' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_one),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers')

          expect(response).to have_http_status(200)

          expect(included.size).to eq(1)
          phone_number_json = included.first
          phone_number_record = contactable_person.phone_numbers.first

          expect(phone_number_json.jsonapi_type).to eq('phone_numbers')

          phone_number_record.attributes.each do |attr, expected|
            expect(phone_number_json.has_key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil
          
          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(['phone_numbers', 'additional_emails'])
        end

        it 'hides certain attributes and relations when show_details is not given' do
          allow_any_instance_of(PersonResource).to receive(:show_details?).and_return(false)

          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
          expect(d.jsonapi_type).to eq('people')

          show_details_attrs.each do |attr|
            expect(d.has_key?(attr)).to eq(false)
          end

        end
      end
    end
  end
end
