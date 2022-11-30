require 'spec_helper'

describe JsonApi::PeopleController, type: [:request] do
  let(:person_attrs) {
    %w(first_name last_name nickname company_name company
       email address zip_code town country gender birthday primary_group_id)
  }

  let(:params) { {} }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  describe '#index' do
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

        it 'returns only people from token`s layer with layer_read permission' do
          permitted_service_token.update!(layer_and_below_read: false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(1)

          person = d.first

          expect(person.id).to eq(top_leader.id)
        end

        it 'returns people filtered/ordered by updated_at' do
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

        it 'paginates entries' do
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

        it 'returns only readable people' do
        end
      end
    end

    context 'with personal oauth access token' do
      context 'authorized' do
        it 'returns people' do
          expect(PersonResource).to receive(:all).and_call_original

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

        it 'returns people ordered by updated_at' do

        end

        it 'returns only readable people' do
        end

        it 'does not return people without role' do
        end
      end
    end
  end
end
