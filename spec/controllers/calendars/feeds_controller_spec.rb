# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Calendars::FeedsController do

  let(:person) { people(:bottom_member) }
  let(:group) { groups(:bottom_layer_one) }
  let(:calendar_token) { 'test-token-1234asdf' }
  let(:calendar) { Fabricate(:calendar, group: group) }
  let!(:calendar_group) { Fabricate(:calendar_group, excluded: false, calendar: calendar, group: group) }
  let!(:event) { Fabricate(:event, groups: [group], name: 'my test event which will appear in the feed') }

  describe 'while logged in' do

    before { sign_in(person) }

    it 'can access token using url' do
      get :index, params: { group_id: group.id, calendar_id: calendar.id, calendar_token: calendar.token }, format: :ics
      expect(response).to be_successful
      expect(response.body.scan('BEGIN:VEVENT')).to have(1).item
      expect(response.body.scan('my test event which will appear in the feed')).to have(1).item
    end

    it 'GET#show.ics returns 404 for bad token' do
      get :index, params: { group_id: group.id, calendar_id: calendar.id, calendar_token: 'wrong-token-IXSvkeJEHe' }, format: :ics
      expect(response.status).to eq 404
    end
  end

  describe 'while logged out' do
    it 'can access token using url' do
      get :index, params: { group_id: group.id, calendar_id: calendar.id, calendar_token: calendar.token }, format: :ics
      expect(response).to be_successful
      expect(response.body.scan('BEGIN:VEVENT')).to have(1).item
      expect(response.body.scan('my test event which will appear in the feed')).to have(1).item
    end

    it 'GET#show.ics returns 404 for bad token' do
      get :index, params: { group_id: group.id, calendar_id: calendar.id, calendar_token: 'wrong-token-IXSvkeJEHe' }, format: :ics
      expect(response.status).to eq 404
    end
  end

end
