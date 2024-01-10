# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Devise::Hitobito::SessionsController do
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:role) { Fabricate('Group::BottomGroup::Member', group: bottom_group) }
  let(:password) { 'cNb@X7fTdiU4sWCMNos3gJmQV_d9e9' }
  let(:person) do
    role.person.update!(password: password)
    role.person.reload
  end

  context 'person has single role' do
    subject { person.roles.first }
    its(:type) { should eq 'Group::BottomGroup::Member' }
    specify 'person has only single role' do
      expect(person.roles.size).to eq 1
    end
  end

  context '#create' do
    before { request.env['devise.mapping'] = Devise.mappings[:person] }

    context '.html' do
      it 'sets flash for invalid login data' do
        post :create , params: { person: { login_identity: person.email, password: 'foobar' } }
        expect(flash[:alert]).to eq 'Ungültige Anmeldedaten.'
        expect(controller.send(:current_person)).not_to be_present
      end

      it 'logs in person even when they have no login permission' do
        post :create, params: { person: { login_identity: person.email, password: password } }
        expect(flash[:alert]).not_to be_present
        expect(controller.send(:current_person)).to be_present
        expect(controller.send(:current_person).authentication_token).to be_blank
      end

      it 'resets person.inactivity_block_warning_sent_at' do
        person.update!(inactivity_block_warning_sent_at: 1.day.ago)
        post :create, params: { person: { login_identity: person.email, password: password } }
        expect(person.reload.inactivity_block_warning_sent_at).to be_nil
      end

      context 'with second factor authentication' do
        before do
          Authenticatable::TwoFactors::Totp.new(person, { pending_totp_secret: 'bla' }).register!
        end

        it 'resets the session and redirects to second factor authentication' do
          post :create, params: { person: { login_identity: person.email, password: password } }

          expect(response).to redirect_to(new_users_second_factor_path)
          expect(session).to_not have_key('warden.user.person.key')
          expect(session).to_not have_key('warden.user.person.session')
          expect(session).to have_key('pending_two_factor_person_id')
          expect(session).to have_key('pending_second_factor_authentication')
        end

        it 'does not clear already present remember_created_at' do
          remember_timestamp = 10.minutes.ago.round # activerecord rounds before saving anyways
          person.update!(remember_created_at: remember_timestamp)

          post :create, params: { person: { email: person.email, password: password } }

          person.reload

          expect(person.remember_created_at).to be_present
          expect(person.remember_created_at).to eq(remember_timestamp)
        end
      end
    end

    context '.json' do

      render_views

      it 'responds with unauthorized for wrong password' do
        post :create, params: { person: { login_identity: person.email, password: 'foobar' } }, format: :json
        expect(response.status).to be(401)
        expect(person.reload.authentication_token).to be_blank
      end

      it 'responds with user and new token' do
        post :create, params: { person: { login_identity: person.email, password: password } }, format: :json
        expect(response.body).to match(/^\{.*"authentication_token":".+"/)
        expect(assigns(:person).authentication_token).to be_present
      end

      it 'responds with user and existing token' do
        person.generate_authentication_token!
        post :create, params: { person: { login_identity: person.email, password: password } }, format: :json
        expect(response.body).to match(/^\{.*"authentication_token":"#{person.authentication_token}"/)
        expect(assigns(:person).authentication_token).to eq(person.authentication_token)
      end
    end

    context 'login_identity' do
      def expect_login_success
        expect(response).to be_redirect
        expect(flash[:alert]).not_to be_present
        expect(controller.send(:current_person)).to eq person
      end

      it 'allows login with email' do
        post :create, params: { person: { login_identity: person.email, password: password } }
        expect_login_success
      end

      context 'customized' do
        around do |example|
          old_attrs = Person.devise_login_id_attrs.dup
          Person.devise_login_id_attrs << :nickname
          example.run
          Person.devise_login_id_attrs = old_attrs
        end

        it 'allows login with nickname' do
          person.update!(nickname: 'foobar')
          post :create, params: { person: { login_identity: 'foobar', password: password } }
          expect_login_success
        end

        it 'allows login with email' do
          post :create, params: { person: { login_identity: person.email, password: password } }
          expect_login_success
        end

        it 'does not allow login with attr absent in devise_login_id_attrs' do
          Person.devise_login_id_attrs = [:nickname]
          post :create, params: { person: { login_identity: person.email, password: password } }
          expect(flash[:alert]).to eq 'Ungültige Anmeldedaten.'
        end
      end
    end
  end

end
