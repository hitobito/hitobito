# encoding: utf-8

#  Copyright (c) 2012-2013, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Devise::TokensController do
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:role) { Fabricate("Group::BottomGroup::Member", group: bottom_group) }
  let(:person) do
    role.person.update_attribute(:password, "password")
    role.person.reload
  end

  before do
    @controller.allow_forgery_protection = true
    @request.env["devise.mapping"] = Devise.mappings[:person]
  end

  render_views

  context "POST create" do
    it "responds with unauthorized with wrong password" do
      post :create, params: {person: {email: person.email, password: "foobar"}}, format: :json
      expect(response.status).to be(401)
      expect(person.reload.authentication_token).to be_blank
    end

    it "responds with unauthorized with token" do
      person.generate_authentication_token!
      post :create, params: {user_email: person.email, user_token: person.authentication_token}, format: :json
      expect(response.status).to be(401)
    end

    it "responds with user and newly generated token" do
      post :create, params: {person: {email: person.email, password: "password"}}, format: :json
      expect(response.body).to match(/^\{.*"authentication_token":".+"/)
      expect(assigns(:person).authentication_token).to be_present
    end

    it "responds with user and regenerated token" do
      person.generate_authentication_token!
      post :create, params: {person: {email: person.email, password: "password"}}, format: :json
      expect(assigns(:person).authentication_token).not_to eq(person.authentication_token)
      expect(assigns(:person).sign_in_count).to eq(person.sign_in_count)
    end
  end

  context "DELETE destroy" do
    it "responds with unauthorized with wrong password" do
      delete :destroy, params: {person: {email: person.email, password: "foobar"}}, format: :json
      expect(response.status).to be(401)
      expect(person.reload.authentication_token).to be_blank
    end

    it "responds with unauthorized with token" do
      person.generate_authentication_token!
      delete :destroy, params: {user_email: person.email, user_token: person.authentication_token}, format: :json
      expect(response.status).to be(401)
    end

    it "responds without token" do
      delete :destroy, params: {person: {email: person.email, password: "password"}}, format: :json
      expect(assigns(:person).authentication_token).to be_nil
      expect(response.body).to match(/^\{.*"authentication_token":null/)
    end

    it "responds with deleted token" do
      person.generate_authentication_token!
      delete :destroy, params: {person: {email: person.email, password: "password"}}, format: :json
      expect(assigns(:person).authentication_token).to be_nil
      expect(assigns(:person).sign_in_count).to eq(person.sign_in_count)
      expect(person.reload.authentication_token).to be_nil
      expect(response.body).to match(/^\{.*"authentication_token":null/)
    end
  end
end
