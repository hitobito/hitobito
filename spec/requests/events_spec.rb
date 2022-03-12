# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "json"

describe 'GET /groups/:group_id/events/:event_id', type: :request do
  let(:application) { Fabricate(:application) }
  let(:event)       { events(:top_course) }
  let(:user)        { people(:bottom_member) }
  let(:event_url)   { "/groups/#{event.group_ids[0]}/events/#{event.id}" }

  context 'without access token' do
    it 'redirects to sign_in' do
      get event_url
      expect(response).to have_http_status(:found)
      expect(response.redirect_url).to eq('http://www.example.com/users/sign_in')
    end
  end

  context 'with bad token signature' do
    let(:token) { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id) }

    it 'redirects to sign_in' do
      get event_url, headers: { 'Authorization': 'Bearer ' + token.token + 'X'}
      expect(response).to have_http_status(:found)
      expect(response.redirect_url).to eq('http://www.example.com/users/sign_in')
    end
  end

  context 'without any scope in token' do
    let(:token) { Fabricate(:access_token, application: application, resource_owner_id: user.id) }

    it 'fails with 403 (forbidden)' do
      get event_url, headers: { 'Authorization': 'Bearer ' + token.token }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'with an unacceptable scope in token' do
    ['email', 'people', 'groups'].each do |scope|
      it "fails for #{scope} scope" do
        token = Fabricate(:access_token, application: application, scopes: { scopes: scope }, resource_owner_id: user.id)
        get event_url, headers: { 'Authorization': 'Bearer ' + token.token }
        expect(response).not_to have_http_status(:success)
      end
    end
  end

  context 'with an acceptable scope in token' do
    ['api', 'events'].each do |scope|
      it "succeeds for #{scope} scope" do
        token = Fabricate(:access_token, application: application, scopes: { scopes: scope }, resource_owner_id: user.id )
        get event_url, headers: { 'Authorization': 'Bearer ' + token.token, 'Accept': 'application/json' }

        expect(response).to be_successful
        expect(response.content_type).to eq('application/json; charset=utf-8')
        events = JSON.parse(response.body)
        expect(events["events"].size).to eq(1)
        expect(events["events"][0]["name"]).to eq(event.name)
      end
    end
  end

  context 'with expired token' do
    let(:token) { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id, expires_in: -1.minute ) }

    it 'redirects to login' do
      get event_url, headers: { 'Authorization': 'Bearer ' + token.token }
      is_expected.to redirect_to('http://www.example.com/users/sign_in')
    end
  end
end
