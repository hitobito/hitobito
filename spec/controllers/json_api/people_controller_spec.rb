require 'spec_helper'

describe JsonApi::PeopleController, type: [:request, :controller] do
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

        it 'returns all people for top_layer token with people_below permission' do
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

        it 'returns only people from token`s group if no people_below permission' do
          permitted_service_token.update!(people_below: false)

          jsonapi_get '/api/people', params: params

          expect(response).to have_http_status(200)
          expect(d.size).to eq(1)

          person = d.first

          expect(person.id).to eq(top_leader.id)
        end

        it 'returns only people from token`s group and below' do
        end

        it 'returns people filtered/ordered by updated_at' do
        end

        it 'returns 403 if token has no people permission' do
          permitted_service_token.update!(people_below: false, people: false)

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
        before { sign_in(top_leader) }

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
