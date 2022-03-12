# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Devise::Hitobito::RegistrationsController do
  before { request.env['devise.mapping'] = Devise.mappings[:person] }
  render_views

  let(:person) { people(:top_leader) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(person) }

  subject { dom }

  describe 'GET #edit' do

    context 'user with password' do
      before { get :edit }
      it { is_expected.to have_content 'Passwort ändern' }
      it { is_expected.to have_content 'Altes Passwort' }
    end

    context 'user without password' do
      before { person.update!(encrypted_password: nil) }
      before { sign_in(person) }

      it 'receives access denied error' do
        expect do
          get :edit
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'put #update' do
    let(:data) { { password: 'foofoofoofoo', password_confirmation: 'foofoofoofoo' } }

    context 'with old password' do
      before { put :update, params: { person: data.merge(current_password: 'foobar') } }

      it { is_expected.to redirect_to(root_path) }
      it { expect(flash[:notice]).to eq 'Dein Passwort wurde aktualisiert.' }
    end

    context 'with wrong old password' do
      before { put :update, params: { person: data.merge(current_password: 'barfoo') } }

      it { is_expected.to render_template('edit') }
      it { is_expected.to have_content 'Altes Passwort ist nicht gültig' }
    end

    context 'without old password' do
      before { put :update, params: { person: data } }

      it { is_expected.to render_template('edit') }
      it { is_expected.to have_content 'Altes Passwort muss ausgefüllt werden' }
    end

    context 'user without password' do
      before { person.update!(encrypted_password: nil) }
      before { sign_in(person) }

      it 'receives access denied error' do
        expect do
          put :update, params: { person: data }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'with wrong confirmation' do
      before { put :update, params: { person: { current_password: 'foobar', passsword: 'foofoofoofoo', password_confirmation: 'barfoobarfoo' } } }

      it { is_expected.to render_template('edit') }
      it { is_expected.to have_content 'Passwort Bestätigung stimmt nicht mit Passwort überein' }
    end


    context 'with empty password' do
      it 'does not change password' do
        old = person.encrypted_password
        put :update, params: { person: { current_password: 'foobar', passsword: '', password_confirmation: '' } }

        is_expected.to redirect_to(root_path)
        expect(person.reload.encrypted_password).to eq(old)
      end
    end
  end
end
