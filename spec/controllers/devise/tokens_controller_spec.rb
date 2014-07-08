# encoding: utf-8

#  Copyright (c) 2012-2013, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Devise::TokensController do

  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:role) { Fabricate('Group::BottomGroup::Member', group: bottom_group) }
  let(:person) do
    role.person.update_attribute(:password, 'password')
    role.person.reload
  end

  before { @request.env["devise.mapping"] = Devise.mappings[:person] }

  render_views

  context 'POST create' do
    it 'responds with unauthorized with wrong password' do
      post :create, person: { email: person.email, password: 'foobar' }, format: :json
      response.status.should be(401)
      person.reload.authentication_token.should be_blank
    end

    it 'responds with unauthorized with token' do
      person.generate_authentication_token!
      post :create, user_email: person.email, user_token: person.authentication_token, format: :json
      response.status.should be(401)
    end

    it 'responds with user and newly generated token' do
      post :create, person: { email: person.email, password: 'password' }, format: :json
      response.body.should match(/^\{.*"authentication_token":".+"/)
      assigns(:person).authentication_token.should be_present
    end

    it 'responds with user and regenerated token' do
      person.generate_authentication_token!
      post :create, person: { email: person.email, password: 'password' }, format: :json
      assigns(:person).authentication_token.should_not eq(person.authentication_token)
      assigns(:person).sign_in_count.should eq(person.sign_in_count)
    end
  end

  context 'DELETE destroy' do
    it 'responds with unauthorized with wrong password' do
      delete :destroy, person: { email: person.email, password: 'foobar' }, format: :json
      response.status.should be(401)
      person.reload.authentication_token.should be_blank
    end

    it 'responds with unauthorized with token' do
      person.generate_authentication_token!
      delete :destroy, user_email: person.email, user_token: person.authentication_token, format: :json
      response.status.should be(401)
    end

    it 'responds without token' do
      delete :destroy, person: { email: person.email, password: 'password' }, format: :json
      assigns(:person).authentication_token.should be_nil
      response.body.should match(/^\{.*"authentication_token":null/)
    end

    it 'responds with deleted token' do
      person.generate_authentication_token!
      delete :destroy, person: { email: person.email, password: 'password' }, format: :json
      assigns(:person).authentication_token.should be_nil
      assigns(:person).sign_in_count.should eq(person.sign_in_count)
      person.reload.authentication_token.should be_nil
      response.body.should match(/^\{.*"authentication_token":null/)
    end
  end


end