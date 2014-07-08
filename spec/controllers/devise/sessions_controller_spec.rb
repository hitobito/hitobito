# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Devise::SessionsController do
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:role) { Fabricate('Group::BottomGroup::Member', group: bottom_group) }
  let(:person) do
    role.person.update_attribute(:password, 'password')
    role.person.reload
  end

  context 'person has single role' do
    subject { person.roles.first }
    its(:type) { should eq 'Group::BottomGroup::Member' }
    specify 'person has only single role' do
      person.roles.size.should eq 1
    end
  end

  context '#create' do
    before { request.env['devise.mapping'] = Devise.mappings[:person] }

    context '.html' do
      it 'sets flash for invalid login data' do
        post :create , person: { email: person.email, password: 'foobar' }
        flash[:alert].should eq 'Ungültige Anmeldedaten.'
        controller.send(:current_person).should_not be_present
      end

      it 'logs in person even when they have no login permission' do
        post :create, person: { email: person.email, password: 'password' }
        flash[:alert].should_not be_present
        controller.send(:current_person).should be_present
        controller.send(:current_person).authentication_token.should be_blank
      end
    end

    context '.json' do

      render_views

      it 'responds with unauthorized for wrong password' do
        post :create, person: { email: person.email, password: 'foobar' }, format: :json
        response.status.should be(401)
        person.reload.authentication_token.should be_blank
      end

      it 'responds with user and new token' do
        post :create, person: { email: person.email, password: 'password' }, format: :json
        response.body.should match(/^\{.*"authentication_token":".+"/)
        assigns(:person).authentication_token.should be_present
      end

      it 'responds with user and existing token' do
        person.generate_authentication_token!
        post :create, person: { email: person.email, password: 'password' }, format: :json
        response.body.should match(/^\{.*"authentication_token":"#{person.authentication_token}"/)
        assigns(:person).authentication_token.should eq(person.authentication_token)
      end
    end
  end

end
