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
    'GET /groups/:id'
  when 'people'
    'GET /groups/:group_id/people/:person_id'
  when 'events'
    'GET /groups/:group_id/events/:event_id'
  when 'invoices'
    'GET /groups/:group_id/invoices/:invoice_id'
  when 'mailing_lists'
    'GET /groups/:group_id/mailing_lists/:mailing_list_id'
  else
    raise 'Unknown scope'
  end
end

scopes = ['groups', 'people', 'events', 'invoices', 'mailing_lists']
sign_in_url = 'http://www.example.com/users/sign_in'

scopes.each do |scope|
  describe get_endpoint(scope), type: :request do
    let(:application)  { Fabricate(:application) }
    let(:user)         { people(:bottom_member) }
    let(:group)        { Group.find(user.group_ids[0]) }
    let(:event)        { events(:top_course) }
    let(:invoice)      { invoices(:invoice) }
    let(:mailing_list) { mailing_lists(:leaders) }
    let(:url)          { get_url(scope) }

    def get_url(scope)
      case scope
      when 'groups'
        "/groups/#{group.id}"
      when 'people'
        "/groups/#{group.id}/people/#{user.id}"
      when 'events'
        "/groups/#{event.group_ids[0]}/events/#{event.id}"
      when 'invoices'
        "/groups/#{invoice.group_id}/invoices/#{invoice.id}"
      when 'mailing_lists'
        "/groups/#{mailing_list.group_id}/mailing_lists/#{mailing_list.id}"
      else
        raise 'Unknown scope'
      end
    end

    def validate_json(scope, json)
      expect(json[scope].size).to eq(1)
      case scope
      when 'groups'
        expect(json[scope][0]["name"]).to eq(group.name)
      when 'people'
        expect(json[scope][0]["email"]).to eq(user.email)
      when 'events'
        expect(json[scope][0]["name"]).to eq(event.name)
      when 'invoices'
        expect(json[scope][0]["title"]).to eq(invoice.title)
      when 'mailing_lists'
        expect(json[scope][0]["mail_name"]).to eq(mailing_list.mail_name)
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
