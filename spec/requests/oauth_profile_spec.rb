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
    let(:token)  { Fabricate(:access_token, application: application, scopes: 'email', resource_owner_id: user.id ) }

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
    let(:token)  { Fabricate(:access_token, application: application, scopes: 'email', resource_owner_id: user.id, expires_in: -1.minute ) }

    it 'fails with 401 (unauthorized)' do
      get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with all scopes in token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: 'email name with_roles', resource_owner_id: user.id ) }

    context 'with scope "name" in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'name' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        json = JSON.parse(response.body)
        expect(json).to match({
                             id: user.id,
                             email: user.email,
                             first_name: user.first_name,
                             last_name: user.last_name,
                             nickname: nil,
                             address: user.address,
                             zip_code: user.zip_code,
                             town: user.town,
                             country: user.country,
                           }.deep_stringify_keys)
      end
    end

    context 'with scope "with_roles" in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'with_roles' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        json = JSON.parse(response.body)
        expect(json).to match({
                             id: user.id,
                             first_name: user.first_name,
                             last_name: user.last_name,
                             nickname: user.nickname,
                             company_name: user.company_name,
                             company: user.company,
                             email: user.email,
                             address: user.address,
                             zip_code: user.zip_code,
                             town: user.town,
                             country: user.country,
                             gender: user.gender,
                             birthday: user.birthday.to_s.presence,
                             primary_group_id: user.primary_group_id,
                             language: user.language,
                             roles: [{
                                       group_id: user.roles.first.group_id,
                                       group_name: user.roles.first.group.name,
                                       role: 'Group::BottomLayer::Member',
                                       role_class: 'Group::BottomLayer::Member',
                                       role_name: 'Member',
                                       permissions: ['layer_and_below_read', 'finance']
                                     }]
                           }.deep_stringify_keys)
      end
    end
  end
end
