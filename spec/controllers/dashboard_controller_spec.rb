#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe DashboardController do
  describe "GET index" do
    context "html" do
      it "redirects to login if no user" do
        get :index
        is_expected.to redirect_to(new_person_session_path)
      end

      it "redirects to user home if logged in" do
        person = people(:top_leader)
        sign_in(person)
        get :index
        is_expected.to redirect_to(group_person_path(person.groups.first, person, format: :html))
      end
    end

    context "json" do
      it "shows error if no user" do
        get :index, format: :json
        expect(response.status).to be(401)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end

      it "redirects to user home if logged in" do
        person = people(:top_leader)
        person.confirm
        person.generate_authentication_token!
        get :index, params: {user_email: person.email, user_token: person.authentication_token}, format: :json
        is_expected.to redirect_to(group_person_path(person.groups.first, person, format: :json))
      end
    end
  end
end
