# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "json"

def get_endpoint(scope)
  case scope
  when 'groups'
    'GET /groups'
  when 'people'
    'GET /groups/:group_id/people'
  when 'events'
    'GET /groups/:group_id/events'
  when 'invoices'
    'GET /groups/:group_id/invoices'
  when 'mailing_lists'
    'GET /groups/:group_id/mailing_lists'
  else
    raise 'Unknown scope'
  end
end

scopes = ['groups', 'people', 'events', 'invoices', 'mailing_lists']
sign_in_url = 'http://www.example.com/users/sign_in'

scopes.each do |scope|
  describe get_endpoint(scope), type: :request do
    let(:application)   { Fabricate(:application) }
    let(:user)          { people(:top_leader) }
    let(:group)         { Group.find(user.group_ids[0]) }
    let(:top_layer)     { groups(:top_layer) }
    let(:top_events)    { [Fabricate(:event, groups: [group]), Fabricate(:event, groups: [group])] }
    let!(:ev_dates)     { [Fabricate(:event_date, event: top_events[0]), Fabricate(:event_date, event: top_events[1])]}
    let!(:top_invoices) { [Fabricate(:invoice, group: top_layer, recipient: user), Fabricate(:invoice, group: top_layer, recipient: user)] }
    let(:url)           { get_url(scope) }

    def get_url(scope)
      case scope
      when 'groups'
        "/groups/#{group.id}"
      when 'people'
        "/groups/#{group.id}/people"
      when 'events'
        "/groups/#{group.id}/events"
      when 'invoices'
        # need to use layer to index invoices
        "/groups/#{top_layer.id}/invoices"
      when 'mailing_lists'
        "/groups/#{top_layer.id}/mailing_lists"
      else
        raise 'Unknown scope'
      end
    end

    def validate_json(scope, json)
      if (!['groups', 'people'].include?(scope))
        # index people is not paged, and index groups redirects to root group
        expect(json['current_page']).to eq 1
        expect(json['total_pages']).to eq 1
        expect(json['next_page_link']).to be_nil
        expect(json['prev_page_link']).to be_nil
      end
      case scope
      when 'groups'
        # index groups redirects to root group
        expect(json[scope].size).to eq(1)
        expect(json[scope][0]['type']).to eq('groups')
        expect(json[scope][0]['id']).to eq(group.id.to_s)
      when 'people'
        expect(json[scope].size).to eq(1)
        expect(json[scope][0]["email"]).to eq(user.email)
      when 'events'
        expect(json[scope].size).to eq(2)
        expect(json[scope].collect { |ev| ev['id'] }).to eq top_events.collect { |ev| ev['id'].to_s }
      when 'invoices'
        expect(json[scope].size).to eq(2)
        expect(json[scope].collect { |i| i['id'] }).to eq top_invoices.collect { |i| i['id'].to_s }
      when 'mailing_lists'
        expect(json[scope].size).to eq(2)
        expect(json[scope].collect { |ml| ml['id'] }).to eq [mailing_lists(:leaders).id.to_s, mailing_lists(:members).id.to_s]
      else
        raise 'Unknown scope'
      end
    end

    context 'without access token' do
      it 'redirects to sign_in' do
        get url
        expect(response).to have_http_status(:found)
        expect(response.redirect_url).to eq(sign_in_url)
      end
    end

    context 'with bad token signature' do
      let(:token) { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id) }

      it 'redirects to sign_in' do
        get url, headers: { 'Authorization': 'Bearer ' + token.token + 'X'}
        expect(response).to have_http_status(:found)
        expect(response.redirect_url).to eq(sign_in_url)
      end
    end

    context 'without any scope in token' do
      let(:token) { Fabricate(:access_token, application: application, resource_owner_id: user.id) }

      it 'fails with 403 (forbidden)' do
        get url, headers: { 'Authorization': 'Bearer ' + token.token }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an unacceptable scope in token' do
      scopes.reject{ |s| s == scope }.each do |invalid_scope|
        it "fails for #{invalid_scope} scope" do
          token = Fabricate(:access_token, application: application, scopes: { scopes: invalid_scope }, resource_owner_id: user.id)
          get url, headers: { 'Authorization': 'Bearer ' + token.token }
          expect(response).not_to have_http_status(:success)
        end
      end
    end

    context 'with an acceptable scope in token' do
      ['api', scope].each do |valid_scope|
        it "succeeds for #{valid_scope} scope" do
          token = Fabricate(:access_token, application: application, scopes: { scopes: valid_scope }, resource_owner_id: user.id )
          get url, headers: { 'Authorization': 'Bearer ' + token.token, 'Accept': 'application/json' }

          expect(response).to be_successful
          expect(response.content_type).to eq('application/json; charset=utf-8')
          json = JSON.parse(response.body)
          validate_json(scope, json)
        end
      end
    end

    context 'with expired token' do
      let(:token) { Fabricate(:access_token, application: application, scopes: { scopes: 'email' }, resource_owner_id: user.id, expires_in: -1.minute ) }

      it 'redirects to login' do
        get url, headers: { 'Authorization': 'Bearer ' + token.token }
        is_expected.to redirect_to(sign_in_url)
      end
    end
  end
end
