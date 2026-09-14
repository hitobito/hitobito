# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe CarddavFeedsController do
  render_views

  let(:person) { people(:bottom_member) }
  let(:token) { "carddav-token-IXSvkeJEH" }

  context "unauthenticated" do
    it "GET#show requires a login" do
      get :show
      expect(response).to redirect_to(new_person_session_path)
    end
  end

  context "signed in" do
    before { sign_in(person) }

    context "before a token is set" do
      it "GET#show renders the page" do
        get :show
        expect(response).to be_successful
        expect(response.body).to include "Zugang erstellen"
      end

      it "PATCH#update creates a token" do
        expect { patch :update }.to change { person.reload.carddav_token }.from(nil)
        expect(flash[:notice]).to eq "Adressbuch-Passwort wurde erstellt."
        expect(response).to redirect_to(carddav_feed_path)
      end
    end

    context "when a token exists" do
      before { person.update!(carddav_token: token) }

      it "GET#show renders the url and the token" do
        get :show
        expect(response).to be_successful
        expect(response.body).to include "http://test.host/carddav/"
        expect(response.body).to include token
      end

      it "PATCH#update resets the token" do
        expect { patch :update }.to change { person.reload.carddav_token }.from(token)
        expect(flash[:notice]).to eq "Adressbuch-Passwort wurde aktualisiert."
      end
    end
  end
end
