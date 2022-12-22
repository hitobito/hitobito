# frozen_string_literal: true

#  Copyright (c) 2022-2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe JsonApi::PeopleController, type: [:request] do
  let(:params) { {} }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  let(:person_attrs) do
    %w(first_name last_name nickname company_name company
       email address zip_code town country gender birthday primary_group_id)
  end

  let(:show_details_attrs) do
    %w(gender birthday)
  end

  describe 'GET #index' do
    context 'unauthorized' do
      it 'returns 401' do
        jsonapi_get '/api/people', params: params

        expect(response).to have_http_status(401)

        errors = jsonapi_errors

        expect(errors.first.status).to eq('401')

        expect(errors.first.title).to eq('Login benötigt')
        expect(errors.first.detail).to eq('Du must dich einloggen bevor du auf diese Resource zugreifen kannst.')
      end
    end

    context 'with service token' do
      context 'authorized' do
        let(:permitted_service_token) { service_tokens(:permitted_top_layer_token) }
        let(:params) { { token: permitted_service_token.token } }

        it 'returns all people with roles for top_layer token with layer_and_below_read permission' do # rubocop:disable Metrics/LineLength
          Fabricate(:role, type: 'Group::BottomLayer::Leader', group: groups(:bottom_layer_two))

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.first

          expect(person.id).to eq(bottom_member.id)
          expect(person.jsonapi_type).to eq('people')

          person_attrs.each do |attr|
            expect(person.attributes.key?(attr)).to eq(true)

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
            expect(person.attributes.key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end

          (person_attrs - selected_attrs).each do |attr|
            expect(person.attributes.key?(attr)).to eq(false)
          end
        end

        it 'returns only people from token`s layer with layer_read permission' do
          permitted_service_token.update!(permission: :layer_read)

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
            expect(person.attributes.key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'returns people with role and contactable relations' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                                group: groups(:bottom_layer_two),
                                                person: Fabricate(:person_with_address_and_phone,
                                                                  additional_emails: [Fabricate(:additional_email)],
                                                                  social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.find { |p| p.id == contactable_person.id }

          expect(person.relationships.size).to eq(4)
          expect(person.relationships.keys).to match_array(%w(phone_numbers social_accounts additional_emails roles))
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
            expect(phone_number_json.attributes.key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil

          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(%w(phone_numbers additional_emails))
        end

        it 'includes roles if include param roles' do
          jsonapi_get '/api/people', params: params.merge(include: 'roles')

          expect(response).to have_http_status(200)
          expect(d.size).to eq(2)

          expect(included.size).to eq(2)
          roles_json = included.first
          expect(included.map(&:jsonapi_type).uniq).to match_array(%w(roles))
        end

        it 'returns 403 if token has no people permission' do
          permitted_service_token.update!(people: false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Zugriff verweigert')
          expect(errors.first.detail).to eq('Du bist nicht berechtigt auf diese Resource zuzugreifen.')
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
            expect(person.attributes.key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'returns people with role and contactable relations' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                                group: groups(:bottom_layer_two),
                                                person: Fabricate(:person_with_address_and_phone,
                                                                  additional_emails: [Fabricate(:additional_email)],
                                                                  social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.find { |p| p.id == contactable_person.id }

          expect(person.relationships.size).to eq(4)
          expect(person.relationships.keys).to match_array(%w(phone_numbers social_accounts additional_emails roles))
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
            expect(phone_number_json.attributes.key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil

          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(%w(phone_numbers additional_emails))
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
            expect(person.attributes.key?(attr)).to eq(true)

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
            expect(person.attributes.key?(attr)).to eq(false)
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
            expect(person.attributes.key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end
        end

        it 'returns only readable people' do
        end

        it 'returns people with contactable and role relations' do
          contactable_person = Fabricate(:role, type: 'Group::BottomLayer::Leader',
                                                group: groups(:bottom_layer_two),
                                                person: Fabricate(:person_with_address_and_phone,
                                                                  additional_emails: [Fabricate(:additional_email)],
                                                                  social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(3)

          person = d.find { |p| p.id == contactable_person.id }

          expect(person.relationships.size).to eq(4)
          expect(person.relationships.keys).to match_array(%w(phone_numbers social_accounts additional_emails roles))
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
            expect(phone_number_json.attributes.key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get '/api/people', params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil

          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(%w(phone_numbers additional_emails))
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
            expect(person.attributes.key?(attr)).to eq(true)

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
            expect(person.attributes.key?(attr)).to eq(false)
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
            expect(person.attributes.key?(attr)).to eq(true)

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
            expect(person.attributes.key?(attr)).to eq(true)

            expect(person.send(attr.to_sym)).to eq(bottom_member.send(attr.to_sym))
          end

          (person_attrs - selected_attrs).each do |attr|
            expect(person.attributes.key?(attr)).to eq(false)
          end
        end

        it 'returns 403 for person with lower roles using token with layer_read permission' do
          permitted_service_token.update!(permission: :layer_read)

          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Zugriff verweigert')
          expect(errors.first.detail).to eq('Du bist nicht berechtigt auf diese Resource zuzugreifen.')
        end

        it 'returns 403 in english if locale param set' do
          permitted_service_token.update!(permission: :layer_read)
          params[:locale] = :en

          jsonapi_get "/api/people/#{bottom_member.id}", params: params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Zugriff verweigert')
          expect(errors.first.detail).to eq('Du bist nicht berechtigt auf diese Resource zuzugreifen.')
        end

        it 'returns person from token`s layer with layer_read permission' do
          person = Fabricate(Group::TopLayer::TopAdmin.to_s, group: groups(:top_layer)).person

          permitted_service_token.update!(permission: :layer_read)

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
        end

        it 'returns person with contactable and roles relations' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                                group: groups(:bottom_layer_two),
                                                person: Fabricate(:person_with_address_and_phone,
                                                                  additional_emails: [Fabricate(:additional_email)],
                                                                  social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params

          expect(response).to have_http_status(200)

          person = d

          expect(person.relationships.size).to eq(4)
          expect(person.relationships.keys).to match_array(%w(phone_numbers social_accounts additional_emails roles))
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
            expect(phone_number_json.attributes.key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil

          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(%w(phone_numbers additional_emails))
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
            expect(d.attributes.key?(attr)).to eq(true)

            expect(d.send(attr.to_sym)).to eq(person.send(attr.to_sym))
          end
        end

        it 'returns people with contactable and roles relations' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                                group: groups(:bottom_layer_one),
                                                person: Fabricate(:person_with_address_and_phone,
                                                                  additional_emails: [Fabricate(:additional_email)],
                                                                  social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.relationships.size).to eq(4)
          expect(d.relationships.keys).to match_array(%w(phone_numbers social_accounts additional_emails roles))
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
            expect(phone_number_json.attributes.key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil

          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(%w(phone_numbers additional_emails))
        end

        it 'hides certain attributes and relations when show_details is not given' do
          allow_any_instance_of(PersonResource).to receive(:show_details?).and_return(false)

          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
          expect(d.jsonapi_type).to eq('people')

          show_details_attrs.each do |attr|
            expect(d.attributes.key?(attr)).to eq(false)
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
            expect(d.attributes.key?(attr)).to eq(true)

            expect(d.send(attr.to_sym)).to eq(person.send(attr.to_sym))
          end
        end

        it 'returns people with contactable and role relations' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                                group: groups(:bottom_layer_one),
                                                person: Fabricate(:person_with_address_and_phone,
                                                                  additional_emails: [Fabricate(:additional_email)],
                                                                  social_accounts: [Fabricate(:social_account)])).person

          jsonapi_get "/api/people/#{contactable_person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.relationships.size).to eq(4)
          expect(d.relationships.keys).to match_array(%w(phone_numbers social_accounts additional_emails roles))
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
            expect(phone_number_json.attributes.key?(attr)).to eq(true)

            expect(phone_number_json.send(attr.to_sym)).to eq(expected)
          end

          jsonapi_get "/api/people/#{contactable_person.id}", params: params.merge(include: 'phone_numbers,additional_emails')

          # purge included instance variable since graphiti spec helper decides to memoize it
          @jsonapi_included = nil

          expect(included.size).to eq(2)
          expect(included.map(&:jsonapi_type)).to match_array(%w(phone_numbers additional_emails))
        end

        it 'hides certain attributes and relations when show_details is not given' do
          allow_any_instance_of(PersonResource).to receive(:show_details?).and_return(false)

          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          jsonapi_get "/api/people/#{person.id}", params: params

          expect(response).to have_http_status(200)

          expect(d.id).to eq(person.id)
          expect(d.jsonapi_type).to eq('people')

          show_details_attrs.each do |attr|
            expect(d.attributes.key?(attr)).to eq(false)
          end

        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:payload) do
      {
        data: {
          id: @person_id.to_s,
          type: 'people',
          attributes: {
            first_name: 'changed'
          }
        }
      }
    end
    let(:params) { payload }

    before { PaperTrail.enabled = true }
    after { PaperTrail.enabled = false }

    context 'unauthorized' do
      it 'returns 401 for existing person id' do
        @person_id = top_leader.id

        jsonapi_patch "/api/people/#{@person_id}", params

        expect(response).to have_http_status(401)
      end

      it 'returns 401 for non existing person' do
        @person_id = Person.maximum(:id).succ

        jsonapi_patch "/api/people/#{@person_id}", params

        expect(response).to have_http_status(401)
      end
    end

    context 'with service token' do
      context 'authorized' do
        let(:permitted_service_token) { service_tokens(:permitted_top_layer_token) }
        let(:params) { payload.merge({ token: permitted_service_token.token }) }

        it 'returns 404 for non existing person' do
          @person_id = Person.maximum(:id).succ

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(404)
        end

        it 'renders validation errors for person' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person
          @person_id = person.id

          params[:data][:attributes][:email] = bottom_member.email
          params[:data][:attributes][:id] = bottom_member.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(422)


          errors = jsonapi_errors

          expect(errors.first.status).to eq('422')
          expect(errors.first.title).to eq('Validation Error')
          expect(errors.first.attribute).to eq('email')
          expect(errors.first.code).to eq('taken')
          expect(errors.first.message).to match /ist bereits vergeben/
        end

        it 'renders translated validation errors for person if locale param' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          @person_id = person.id

          params[:data][:attributes][:email] = bottom_member.email

          jsonapi_patch "/api/people/#{@person_id}?locale=de", params

          expect(response).to have_http_status(422)


          errors = jsonapi_errors

          expect(errors.first.status).to eq('422')
          expect(errors.first.title).to eq('Validation Error')
          expect(errors.first.attribute).to eq('email')
          expect(errors.first.message).to match /ist bereits vergeben/
        end

        it 'updates person with lower roles for top_layer token with layer_and_below_full permission' do
          @person_id = bottom_member.id
          former_first_name = bottom_member.first_name

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          bottom_member.reload

          expect(bottom_member.first_name).to eq('changed')

          latest_change = bottom_member.versions.last

          changes = YAML.load(latest_change.object_changes)
          expect(changes).to eq({ 'first_name' => [ former_first_name, 'changed' ]})
          expect(latest_change.perpetrator).to eq(permitted_service_token)
        end

        it 'returns 403 for person with lower roles using token with layer_read permission' do
          permitted_service_token.update!(permission: :layer_read)

          @person_id = bottom_member.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Zugriff verweigert')
          expect(errors.first.detail).to eq('Du bist nicht berechtigt auf diese Resource zuzugreifen.')
        end

        it 'returns 403 in german if locale param set' do
          permitted_service_token.update!(permission: :layer_read)

          @person_id = bottom_member.id

          jsonapi_patch "/api/people/#{@person_id}?locale=de", params

          expect(response).to have_http_status(403)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('403')
          expect(errors.first.title).to eq('Zugriff verweigert')
          expect(errors.first.detail).to eq('Du bist nicht berechtigt auf diese Resource zuzugreifen.')
        end

        it 'updates person from token`s layer with layer_full permission' do
          person = Fabricate(Group::TopLayer::TopAdmin.to_s, group: groups(:top_layer)).person

          permitted_service_token.update!(permission: :layer_full)

          @person_id = person.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          person.reload

          expect(person.first_name).to eq('changed')
        end

        it 'updates also person`s detail attributes' do
          person = Fabricate(Group::TopLayer::TopAdmin.to_s, group: groups(:top_layer)).person

          permitted_service_token.update!(permission: :layer_full)

          @person_id = person.id

          payload[:data][:attributes][:birthday] = '1985-08-01'

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          person.reload

          expect(person.birthday).to eq(Date.parse('1985-08-01'))
        end

        it 'does not update inaccessible person by overriding payloads person id' do
          person = Fabricate(Group::TopLayer::TopAdmin.to_s, group: groups(:top_layer)).person
          inaccessible_person = bottom_member

          permitted_service_token.update!(permission: :layer_full)

          @person_id = person.id

          payload[:data][:id] = inaccessible_person.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(400)

          person.reload
          expect(person.first_name).not_to eq('changed')

          inaccessible_person.reload
          expect(inaccessible_person.first_name).not_to eq('changed')
        end

        it 'does not update any protected person attributes' do
          person = Fabricate(Group::TopLayer::TopAdmin.to_s, group: groups(:top_layer)).person
          password_hash = person.encrypted_password

          permitted_service_token.update!(permission: :layer_full)

          @person_id = person.id

          payload[:data][:attributes][:encrypted_password] = 'my-sweet-manipulated-hash'

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(400)

          person.reload
          expect(person.first_name).not_to eq('changed')
          expect(person.encrypted_password).to eq(password_hash)
        end

        it 'returns validation error for contactable relations of person' do
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [Fabricate(:additional_email)],
                                                           social_accounts: [Fabricate(:social_account)])).person

          phone_number = contactable_person.phone_numbers.first

          @person_id = contactable_person.id

          params[:data][:relationships] = {
            phone_numbers: {
              data: [{
                type: 'phone_numbers',
                id: phone_number.id,
                method: 'update'
              }]
            }
          }
          params[:included] = [
            {
              type: 'phone_numbers',
              id: phone_number.id,
              attributes: {
                number: ''
              }
            }
          ]

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(422)

          errors = jsonapi_errors

          expect(errors.first.status).to eq('422')
          expect(errors.first.title).to eq('Validation Error')
          expect(errors.first.to_json).to include('"source":{"pointer":"/data/attributes/number"}')
          expect(errors.first.detail).to eq('Nummer ist nicht gültig')
        end

        it 'updates contactable relations of person' do
          email = Fabricate(:additional_email)
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_two),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [email],
                                                           social_accounts: [Fabricate(:social_account)])).person

          @person_id = contactable_person.id

          params[:data][:relationships] = {
            additional_emails: {
              data: [{
                type: 'additional_emails',
                id: email.id,
                method: 'update',
              }]
            }
          }
          params[:included] = [
            {
              type: 'additional_emails',
              id: email.id,
              attributes: {
                email: 'changed.hitobito@example.com'
              }
            }
          ]

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          email.reload

          expect(email.email).to eq('changed.hitobito@example.com')
        end

        it 'returns 403 if token has no people permission' do
          permitted_service_token.update!(people: false)

          @person_id = bottom_member.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'with signed in user session' do
      context 'authorized' do
        let(:bottom_layer_leader) { Fabricate(Group::BottomLayer::Leader.to_s, group: groups(:bottom_layer_one)).person }

        before do
          sign_in(bottom_layer_leader)
          # mock check for user since sign_in devise helper is not setting any cookies
          allow_any_instance_of(described_class)
            .to receive(:user_session?).and_return(true)
        end

        it 'returns 404 for non existing person' do
          @person_id = Person.maximum(:id).succ

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(404)
        end

        it 'returns 403 for person without access' do
          @person_id = top_leader.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(403)
        end

        it 'renders validation errors for person' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          @person_id = person.id

          params[:data][:attributes][:email] = bottom_member.email

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(422)


          errors = jsonapi_errors

          expect(errors.first.status).to eq('422')
          expect(errors.first.title).to eq('Validation Error')
          expect(errors.first.attribute).to eq('email')
          expect(errors.first.code).to eq('taken')
        end

        it 'updates person with access' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person
          former_first_name = person.first_name

          @person_id = person.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          person.reload

          expect(person.first_name).to eq('changed')

          latest_change = person.versions.last

          changes = YAML.load(latest_change.object_changes)
          expect(changes).to eq({ 'first_name' => [ former_first_name, 'changed' ]})
          expect(latest_change.perpetrator).to eq(bottom_layer_leader)
        end

        it 'does not update person`s detail attributes without required permission' do
          allow_any_instance_of(PersonResource).to receive(:write_details?).and_return(false)
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          @person_id = person.id

          payload[:data][:attributes][:birthday] = '1985-08-01'

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(400)

          person.reload

          expect(person.birthday).not_to eq(Date.parse('1985-08-01'))
        end

        it 'does not update person if wrong content type header' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person
          former_first_name = person.first_name

          @person_id = person.id

          headers = { 'CONTENT_TYPE' => 'application/json' }

          jsonapi_patch "/api/people/#{@person_id}", params, headers: headers

          expect(response).to have_http_status(415)
        end

        it 'updates contactable relations of person' do
          email = Fabricate(:additional_email)
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_one),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [email],
                                                           social_accounts: [Fabricate(:social_account)])).person

          @person_id = contactable_person.id

          params[:data][:relationships] = {
            additional_emails: {
              data: [{
                type: 'additional_emails',
                id: email.id,
                method: 'update',
              }]
            }
          }
          params[:included] = [
            {
              type: 'additional_emails',
              id: email.id,
              attributes: {
                email: 'changed.hitobito@example.com'
              }
            }
          ]

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          email.reload

          expect(email.email).to eq('changed.hitobito@example.com')
        end
      end
    end

    context 'with personal oauth access token' do
      context 'authorized' do
        let(:token_owner) { Fabricate(Group::BottomLayer::Leader.to_s, group: groups(:bottom_layer_one)).person }
        let(:token) { Fabricate(:access_token, resource_owner_id: token_owner.id) }

        before do
          allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { token }
          allow(token).to receive(:acceptable?) { true }
          allow(token).to receive(:accessible?) { true }
          allow_any_instance_of(described_class).to receive(:current_oauth_token) { token }
        end

        it 'returns 404 for non existing person' do
          @person_id = Person.maximum(:id).succ

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(404)
        end

        it 'returns 403 for person without access' do
          @person_id = top_leader.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(403)
        end

        it 'renders validation errors for person' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person

          @person_id = person.id

          params[:data][:attributes][:email] = bottom_member.email

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(422)


          errors = jsonapi_errors

          expect(errors.first.status).to eq('422')
          expect(errors.first.title).to eq('Validation Error')
          expect(errors.first.attribute).to eq('email')
          expect(errors.first.code).to eq('taken')
        end

        it 'updates person with access' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person
          former_first_name = person.first_name

          @person_id = person.id

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          person.reload
          expect(person.first_name).to eq('changed')

          latest_change = person.versions.last

          changes = YAML.load(latest_change.object_changes)
          expect(changes).to eq({ 'first_name' => [ former_first_name, 'changed' ]})
          expect(latest_change.perpetrator).to eq(token_owner)
        end

        it 'updates contactable relations of person' do
          email = Fabricate(:additional_email)
          contactable_person = Fabricate(:role, type: Group::BottomLayer::Member.to_s,
                                         group: groups(:bottom_layer_one),
                                         person: Fabricate(:person_with_address_and_phone,
                                                           additional_emails: [email],
                                                           social_accounts: [Fabricate(:social_account)])).person

          @person_id = contactable_person.id

          params[:data][:relationships] = {
            additional_emails: {
              data: [{
                type: 'additional_emails',
                id: email.id,
                method: 'update',
              }]
            }
          }
          params[:included] = [
            {
              type: 'additional_emails',
              id: email.id,
              attributes: {
                email: 'changed.hitobito@example.com'
              }
            }
          ]

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          email.reload

          expect(email.email).to eq('changed.hitobito@example.com')
        end

        it 'creates new contactable on person update' do
          person = Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person
          @person_id = person.id

          params[:data][:relationships] = {
            additional_emails: {
              data: [{
                type: 'additional_emails',
                method: 'create',
              }]
            }
          }
          params[:included] = [
            {
              type: 'additional_emails',
              attributes: {
                label: 'Ds Grosi',
                contactable_type: 'additional_emails',
                email: 'new.hitobito@example.com'
              }
            }
          ]

          jsonapi_patch "/api/people/#{@person_id}", params

          expect(response).to have_http_status(200)

          person.reload

          expect(person.additional_emails.first.email).to eq('new.hitobito@example.com')
        end
      end
    end
  end
end
