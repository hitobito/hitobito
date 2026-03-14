#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Oauth::ApplicationsController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  it "POST#create creates application with custom scopes" do
    post :create,
      params: {oauth_application: {name: "MyApp", redirect_uri: "urn:ietf:wg:oauth:2.0:oob", scopes: %w[name email]}}
    application = Oauth::Application.find_by(name: "MyApp")
    expect(application.scopes).to eq %w[name email]
  end

  describe "description field" do
    let(:description_text) { "Wird verwendet für den internen Mitgliederbereich." }

    it "POST#create saves description" do
      post :create,
        params: {oauth_application: {
          name: "MyApp",
          redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
          description: description_text
        }}
      application = Oauth::Application.find_by(name: "MyApp")
      expect(application.description).to eq description_text
    end

    context "with existing application" do
      let!(:application) do
        Oauth::Application.create!(
          name: "ExistingApp",
          redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
        )
      end

      it "PATCH#update saves description" do
        patch :update,
          params: {id: application.id, oauth_application: {description: description_text}}
        expect(application.reload.description).to eq description_text
      end

      it "GET#show assigns entry with description" do
        application.update!(description: description_text)
        get :show, params: {id: application.id}
        expect(response).to be_successful
        expect(assigns(:application).description).to eq description_text
      end
    end
  end
end
