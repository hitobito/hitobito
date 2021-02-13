# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventFeedsController do
  let(:person) { people(:bottom_member) }
  let(:token) { "test-token-IXSvkeJEHeo" }

  describe "while logged in" do
    before { sign_in(person) }

    context "before token is set" do
      before { person.update_attribute(:event_feed_token, nil) }

      it "GET#show renders page" do
        get :show
        expect(response).to be_successful
      end

      it "GET#show.ics returns 404 without token" do
        get :show, format: :ics
        expect(response.status).to eq 404
      end

      it "PATCH#update creates token" do
        expect { patch :update }.to change { person.reload.event_feed_token }
        expect(flash[:notice]).to eq "Adresse wurde erstellt."
        expect(response).to redirect_to(event_feed_path)
      end
    end

    context "when token exists" do
      before { person.update_attribute(:event_feed_token, token) }

      it "GET#show renders page" do
        get :show
        expect(response).to be_successful
      end

      it "GET#show.ics returns feed" do
        get :show, params: {token: token}, format: :ics
        expect(response).to have_http_status(:ok)
        expect(response.body.scan("BEGIN:VEVENT")).to have(1).item
      end

      it "GET#show.ics returns 404 for bad token" do
        get :show, params: {token: "wrong-token-IXSvkeJEHe"}, format: :ics
        expect(response.status).to eq 404
      end

      it "PATCH#update resets token" do
        expect { post :update }.to change { person.reload.event_feed_token }
        expect(flash[:notice]).to eq "Adresse wurde aktualisiert."
        expect(response).to redirect_to(event_feed_path)
      end
    end
  end

  describe "while logged out" do
    before do
      person.update_attribute(:event_feed_token, token)
    end

    it "can access token using url" do
      get :show, params: {token: person.event_feed_token}, format: :ics
      expect(response).to have_http_status(:ok)
    end

    it "access denied when using wrong token" do
      get :show, params: {token: "wrong-token-IXSvkeJEHe"}, format: :ics
      expect(response).to have_http_status(404)
    end

    context "with event participations" do
      let!(:past_event_date) { Fabricate(:event_date, event: past_event, start_at: Time.zone.now - 1.year) }
      let!(:future_event_date) { Fabricate(:event_date, event: future_event, start_at: Time.zone.now + 1.year) }
      let(:past_event) { Fabricate(:event, name: "Past event") }
      let(:future_event) { Fabricate(:event, name: "Future event") }
      let!(:past_event_participation) { Fabricate(:event_participation, event: past_event, person: person) }
      let!(:future_event_participation) { Fabricate(:event_participation, event: future_event, person: person) }

      it "includes past event" do
        get :show, params: {token: person.event_feed_token}, format: :ics
        expect(response.body).to include(past_event.name)
      end

      it "includes future event" do
        get :show, params: {token: person.event_feed_token}, format: :ics
        expect(response.body).to include(future_event.name)
      end
    end
  end
end
