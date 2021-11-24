# frozen_string_literal: true

#  Copyright (c) 2020-2021, Aargauer OL-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "json"

RSpec.describe 'GET /groups/:id', type: :request do
  let(:application) { Fabricate(:application) }
  let(:user)        { people(:bottom_member) }

  context 'without access token' do
    it 'redirects to sign_in' do
      get "/groups/#{user.group_ids[0]}"
      expect(response).to have_http_status(:found)
      expect(response.redirect_url).to eq('http://www.example.com/users/sign_in')
    end
  end

  context 'without any scope in token' do
    let(:token)  { Fabricate(:access_token, application: application, resource_owner_id: user.id) }

    it 'fails with 403 (forbidden)' do
      get "/groups/#{user.group_ids[0]}", headers: { 'Authorization': 'Bearer ' + token.token }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'without api scope in token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id) }

    it 'fails with 403 (forbidden)' do
      get "/groups/#{user.group_ids[0]}", headers: { 'Authorization': 'Bearer ' + token.token }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'with api scope in token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: { scopes: 'api' }, resource_owner_id: user.id ) }

    context 'with bad token signature' do
      it 'redirects to sign_in' do
        get "/groups/#{user.group_ids[0]}", headers: { 'Authorization': 'Bearer ' + token.token + 'X'}
        expect(response).to have_http_status(:found)
        expect(response.redirect_url).to eq('http://www.example.com/users/sign_in')
      end
    end

    context 'with valid token' do
      it 'succeeds' do
        get "/groups/#{user.group_ids[0]}", headers: { 'Authorization': 'Bearer ' + token.token, 'Accept': 'application/json' }

        expect(response).to be_successful
        expect(response.content_type).to eq('application/json; charset=utf-8')
        group = JSON.parse(response.body)
        expect(group["groups"].size).to eq(1)
        expect(group["groups"][0]["name"]).to eq("Bottom One")
      end
    end
  end

  context 'with expired token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id, expires_in: -1.minute ) }

    it 'redirects to login' do
      get "/groups/#{user.group_ids[0]}", headers: { 'Authorization': 'Bearer ' + token.token }
      is_expected.to redirect_to('http://www.example.com/users/sign_in')
    end
  end
end
