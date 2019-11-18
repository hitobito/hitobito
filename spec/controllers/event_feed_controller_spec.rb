# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventFeedController do

  let(:person)   { people(:bottom_member) }
  let(:token)    { 'test-token-IXSvkeJEHeo' }

  before { sign_in(person) }

  describe 'while logged in' do

    context 'before token is set' do

      before { person.update_attribute(:event_feed_token, nil) }

      it 'read calendar integration page' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'create token' do
        expect { post :reset }.to change { person.reload.event_feed_token }
      end
    end

    context 'when token exists' do

      before { person.update_attribute(:event_feed_token, token) }

      it 'read calendar integration page' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'reset token' do
        expect { post :reset }.to change { person.reload.event_feed_token }
      end

      it 'can access token using url' do
        get :feed, person_id: person.id, token: person.event_feed_token
        expect(response).to have_http_status(:ok)
      end

      it 'access denied when using wrong token' do
        get :feed, person_id: person.id, token: 'wrong-token-IXSvkeJEHe'
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'while logged out' do

    before do
      person.update_attribute(:event_feed_token, token)
      sign_out(person)
    end

    it 'can access token using url' do
      get :feed, person_id: person.id, token: person.event_feed_token
      expect(response).to have_http_status(:ok)
    end

    it 'access denied when using wrong token' do
      get :feed, person_id: person.id, token: 'wrong-token-IXSvkeJEHe'
      expect(response).to have_http_status(401)
    end

    context 'with event participations' do

      let!(:past_event_date)   { Fabricate(:event_date, event: past_event, start_at: Time.zone.now - 1.year) }
      let!(:future_event_date) { Fabricate(:event_date, event: future_event, start_at: Time.zone.now + 1.year) }
      let(:past_event)   { Fabricate(:event, name: 'Past event') }
      let(:future_event) { Fabricate(:event, name: 'Future event' ) }
      let!(:past_event_participation)   { Fabricate(:event_participation, event: past_event, person: person) }
      let!(:future_event_participation) { Fabricate(:event_participation, event: future_event, person: person) }

      it 'includes past event' do
        get :feed, person_id: person.id, token: person.event_feed_token
        expect(response.body).to include(past_event.name)
      end

      it 'includes future event' do
        get :feed, person_id: person.id, token: person.event_feed_token
        expect(response.body).to include(future_event.name)
      end

    end

  end

end
