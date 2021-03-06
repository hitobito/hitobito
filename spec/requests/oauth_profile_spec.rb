# frozen_string_literal: true

#  Copyright (c) 2020-2021, Aargauer OL-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe 'GET oauth/profile', type: :request do
  let(:application) { Fabricate(:application) }
  let(:user)        { people(:bottom_member) }

  context 'without access token' do
    it 'fails with HTTP 401 (unauthorized)' do
      get '/oauth/profile'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'without scope in token' do
    let(:token)  { Fabricate(:access_token, application: application, resource_owner_id: user.id) }

    it 'fails with HTTP 403 (forbidden)' do
      get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token }

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'with email scope in token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id ) }
    
    context 'with bad token signature' do
      it 'fails with HTTP 401 (unauthorized)' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token + 'X'}
  
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with wrong scope in request' do
      it 'fails with HTTP 403 (forbidden)' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'name' }
        
        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.body).to eq('{"error":"invalid scope: name"}')
      end
    end

    context 'without scope in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.body).to eq("{\"id\":#{user.id},\"email\":\"#{user.email}\"}")
      end
    end

    context 'with email scope in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'email' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.body).to eq("{\"id\":#{user.id},\"email\":\"#{user.email}\"}")
      end
    end
  end

  context 'with expired token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id, expires_in: -1.minute ) }

    it 'fails with 401 (unauthorized)' do
      get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token }

      expect(response).to have_http_status(:unauthorized)  
    end
  end

  context 'with all scopes in token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: { scopes: 'email name with_roles events' }, resource_owner_id: user.id ) }

    context 'with scope "name" in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'name' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.body).to eq("{" +
          "\"id\":#{user.id}," +
          "\"email\":\"#{user.email}\"," +
          "\"first_name\":\"#{user.first_name}\"," +
          "\"last_name\":\"#{user.last_name}\"," +
          "\"nickname\":null" +
          "}")
      end
    end

    context 'with scope "with_roles" in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'with_roles' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.body).to include('"group_name":"Bottom One","role_name":"Member"')
      end
    end

    context 'with scope "events" in request' do
      let(:event) { events(:top_course) }
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'events' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        json = JSON.parse(response.body).deep_symbolize_keys
        expect(json[:events]).to have(1).items
        expect(json[:events].first[:event_name]).to eq(event.name)
        expect(json[:events].first[:event_kind]).to eq(event.kind.label)
        expect(json[:events].first[:roles]).to have(1).items
        expect(json[:events].first[:roles].first[:type]).to eq(event_roles(:top_leader).type)
      end
    end
  end
end
