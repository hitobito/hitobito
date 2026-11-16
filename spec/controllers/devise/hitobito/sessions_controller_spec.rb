#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Devise::Hitobito::SessionsController do
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:role) { Fabricate("Group::BottomGroup::Member", group: bottom_group) }
  let(:password) { "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9" }
  let(:person) do
    role.person.update!(password: password)
    role.person.reload
  end

  context "person has single role" do
    subject { person.roles.first }

    its(:type) { should eq "Group::BottomGroup::Member" }
    specify "person has only single role" do
      expect(person.roles.size).to eq 1
    end
  end

  context "#new" do
    render_views

    let!(:application) do
      Oauth::Application.create!(name: "MyApp", uid: "my-app-uid", redirect_uri: "urn:ietf:wg:oauth:2.0:oob")
    end
    let(:page) { Capybara.string(response.body) }

    before do
      request.env["devise.mapping"] = Devise.mappings[:person]
      session["person_return_to"] = "/oauth/authorize?client_id=my-app-uid&response_type=code"
    end

    it "does not check remember me" do
      get :new, params: {oauth: true}
      expect(page).to have_unchecked_field("person_remember_me")
    end

    it "shows oauth application info" do
      get :new, params: {oauth: true}
      expect(page).to have_content("Bitte melde dich an, um weiter zu MyApp zu gelangen.")
    end

    context "with oauth application preselecting remember me" do
      before { application.update!(preselect_remember_me: true) }

      it "checks remember me" do
        get :new, params: {oauth: true}
        expect(page).to have_checked_field("person_remember_me")
      end

      it "keeps remember me unchecked if submitted unchecked" do
        get :new, params: {oauth: true, person: {login_identity: "foo", remember_me: "0"}}
        expect(page).to have_unchecked_field("person_remember_me")
      end

      it "does not check remember me without oauth param" do
        get :new
        expect(page).to have_unchecked_field("person_remember_me")
      end
    end

    it "does not check remember me for unknown client_id" do
      session["person_return_to"] = "/oauth/authorize?client_id=unknown"
      get :new, params: {oauth: true}
      expect(page).to have_unchecked_field("person_remember_me")
    end

    [
      "/oauth/authorize",
      "/oauth/authorize?client_id%5Ba%5D=my-app-uid",
      "/oauth/authorize?client_id%5B%5D=my-app-uid",
      "/oauth/authorize?client_id=my-app-uid&client_id%5B%5D=def",
      "/oauth/authorize?client_id=my-app-uid&a=%25zz%",
      "http://[invalid"
    ].each do |return_to|
      it "renders without oauth application info for stored location #{return_to}" do
        session["person_return_to"] = return_to
        get :new, params: {oauth: true}
        expect(page).to have_content("Bitte melde dich an, um weiter zu gelangen.")
        expect(page).not_to have_content("MyApp")
      end
    end

    it "does not check remember me without stored location" do
      session.delete("person_return_to")
      get :new, params: {oauth: true}
      expect(page).to have_unchecked_field("person_remember_me")
    end
  end

  context "#create" do
    before { request.env["devise.mapping"] = Devise.mappings[:person] }

    context ".html" do
      it "sets flash for invalid login data" do
        post :create, params: {person: {login_identity: person.email, password: "foobar"}}
        expect(flash[:alert]).to eq "Ungültige Anmeldedaten."
        expect(controller.send(:current_person)).not_to be_present
      end

      it "logs in person even when they have no login permission" do
        post :create, params: {person: {login_identity: person.email, password: password}}
        expect(flash[:alert]).not_to be_present
        expect(controller.send(:current_person)).to be_present
        expect(controller.send(:current_person).authentication_token).to be_blank
      end

      it "resets person.inactivity_block_warning_sent_at" do
        person.update!(inactivity_block_warning_sent_at: 1.day.ago)
        post :create, params: {person: {login_identity: person.email, password: password}}
        expect(person.reload.inactivity_block_warning_sent_at).to be_nil
      end

      context "with second factor authentication" do
        before do
          Authenticatable::TwoFactors::Totp.new(person, {pending_totp_secret: "bla"}).register!
        end

        it "resets the session and redirects to second factor authentication" do
          post :create, params: {person: {login_identity: person.email, password: password}}

          expect(response).to redirect_to(new_users_second_factor_path)
          expect(session).to_not have_key("warden.user.person.key")
          expect(session).to_not have_key("warden.user.person.session")
          expect(session).to have_key("pending_two_factor_person_id")
          expect(session).to have_key("pending_second_factor_authentication")
        end

        it "does not clear already present remember_created_at" do
          remember_timestamp = 10.minutes.ago.round # activerecord rounds before saving anyways
          person.update!(remember_created_at: remember_timestamp)

          post :create, params: {person: {email: person.email, password: password}}

          person.reload

          expect(person.remember_created_at).to be_present
          expect(person.remember_created_at).to eq(remember_timestamp)
        end
      end
    end

    context "login_identity" do
      def expect_login_success
        expect(response).to be_redirect
        expect(flash[:alert]).not_to be_present
        expect(controller.send(:current_person)).to eq person
      end

      it "allows login with email" do
        post :create, params: {person: {login_identity: person.email, password: password}}
        expect_login_success
      end

      context "customized" do
        around do |example|
          old_attrs = Person.devise_login_id_attrs.dup
          Person.devise_login_id_attrs << :nickname
          example.run
          Person.devise_login_id_attrs = old_attrs
        end

        it "allows login with nickname" do
          person.update!(nickname: "foobar")
          post :create, params: {person: {login_identity: "foobar", password: password}}
          expect_login_success
        end

        it "allows login with email" do
          post :create, params: {person: {login_identity: person.email, password: password}}
          expect_login_success
        end

        it "does not allow login with attr absent in devise_login_id_attrs" do
          Person.devise_login_id_attrs = [:nickname]
          post :create, params: {person: {login_identity: person.email, password: password}}
          expect(flash[:alert]).to eq "Ungültige Anmeldedaten."
        end
      end
    end
  end
end
