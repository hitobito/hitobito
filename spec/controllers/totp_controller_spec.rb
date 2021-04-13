# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

require 'spec_helper'

describe TotpController do
  let(:bottom_member) { people(:bottom_member) }
  let(:totp_authenticator) { People::OneTimePassword.new(@secret).send(:authenticator) }

  describe 'create' do
    it 'redirects to root if no two factor authentication is pending' do
      post :create

      expect(response).to redirect_to root_path
    end

    it 'redirects to root if person locked' do
      bottom_member.lock_access!

      session[:pending_two_factor_person_id] = bottom_member.id

      post :create

      expect(response).to redirect_to root_path
      expect(flash[:alert]).to include('Dein Account ist für 10 Minuten gesperrt')
    end

    context 'as not signed in person' do
      context 'when registered' do
        before do
          @secret = People::OneTimePassword.generate_secret

          bottom_member.second_factor_auth = :totp
          bottom_member.totp_secret = @secret
          bottom_member.save!

          session[:pending_two_factor_person_id] = bottom_member.id

          expect(bottom_member.second_factor_auth).to eq('totp')
          expect(bottom_member.totp_secret).to eq(@secret)
          expect(bottom_member.totp_registered?).to be(true)
          expect(controller.send(:current_person)).to be_nil
        end

        it 'signs in with correct TOTP code' do

          post :create, params: { totp_code: totp_authenticator.now }

          expect(response).to redirect_to root_path

          bottom_member.reload

          expect(bottom_member.second_factor_auth).to eq('totp')
          expect(bottom_member.totp_secret).to eq(@secret)
          expect(bottom_member.totp_registered?).to be(true)
          expect(controller.send(:current_person)).to eq(bottom_member)
        end

        it 'does not sign in with incorrect TOTP code' do

          post :create, params: { totp_code: totp_authenticator.now.to_i - 1 }

          expect(response).to redirect_to new_users_totp_path

          bottom_member.reload

          expect(bottom_member.second_factor_auth).to eq('totp')
          expect(bottom_member.totp_secret).to eq(@secret)
          expect(bottom_member.totp_registered?).to be(true)
          expect(controller.send(:current_person)).to be_nil
        end
      end

      context 'when unregistered' do
        before do
          bottom_member.update!(second_factor_auth: :totp)

          session[:pending_two_factor_person_id] = bottom_member.id

          @secret = People::OneTimePassword.generate_secret

          session[:pending_totp_secret] = @secret

          expect(bottom_member.second_factor_auth).to eq('totp')
          expect(bottom_member.encrypted_totp_secret).to be_nil
          expect(bottom_member.totp_registered?).to be(false)
          expect(controller.send(:current_person)).to be_nil
        end

        it 'registers TOTP with correct code and signs in' do

          post :create, params: { totp_code: totp_authenticator.now }

          expect(response).to redirect_to root_path

          bottom_member.reload

          expect(bottom_member.second_factor_auth).to eq('totp')
          expect(bottom_member.totp_secret).to eq(@secret)
          expect(bottom_member.totp_registered?).to be(true)
          expect(controller.send(:current_person)).to eq(bottom_member)
        end

        it 'does not register TOTP with incorrect code and does not sign in' do

          post :create, params: { totp_code: totp_authenticator.now.to_i - 1 }

          expect(response).to redirect_to new_users_totp_path

          bottom_member.reload

          expect(bottom_member.second_factor_auth).to eq('totp')
          expect(bottom_member.encrypted_totp_secret).to be_nil
          expect(bottom_member.totp_registered?).to be(false)
          expect(controller.send(:current_person)).to be_nil
        end
      end
    end

    context 'as signed in person' do
      before do
        sign_in bottom_member

        @secret = People::OneTimePassword.generate_secret

        session[:pending_totp_secret] = @secret

        expect(bottom_member.second_factor_auth).to eq('no_second_factor')
        expect(bottom_member.encrypted_totp_secret).to be_nil
      end

      it 'registers TOTP with correct code' do
        session[:pending_two_factor_person_id] = bottom_member.id

        post :create, params: { totp_code: totp_authenticator.now }

        bottom_member.reload

        expect(response).to redirect_to root_path

        expect(bottom_member.second_factor_auth).to eq('totp')
        expect(bottom_member.totp_secret).to eq(@secret)
        expect(bottom_member.totp_registered?).to be(true)
      end

      it 'does not register TOTP with incorrect code' do
        session[:pending_two_factor_person_id] = bottom_member.id

        post :create, params: { totp_code: totp_authenticator.now.to_i - 1 }

        bottom_member.reload

        expect(response).to redirect_to new_users_totp_path

        expect(bottom_member.second_factor_auth).to eq('no_second_factor')
        expect(bottom_member.encrypted_totp_secret).to be_nil
        expect(bottom_member.totp_registered?).to be(false)
      end
    end
  end
end
