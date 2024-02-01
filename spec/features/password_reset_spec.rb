# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'password reset', js: true do

  subject { page }
  let(:person) { people(:bottom_member) }
  let(:password) { 'asdfasdfasdfasdf' }

  context 'send login to' do
    let(:me) { people(:top_leader) }
    let(:link) { click_send_login_button(person, me) }

    context 'person without login' do
      let(:person) do
        person = people(:bottom_member)
        person.update_columns(encrypted_password: nil)
        person
      end

      it 'should require at least 12 characters' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: 'test'
          fill_in 'Neues Passwort bestätigen', with: 'test'
          click_button 'Passwort ändern'
          is_expected.to have_text('Passwort ist zu kurz (weniger als 12 Zeichen)')
        end.not_to(change { person.reload.encrypted_password })
      end

      it 'should not be signed in automatically after password reset' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: password
          fill_in 'Neues Passwort bestätigen', with: password
          click_button 'Passwort ändern'
          is_expected.to have_text('Anmelden')
          is_expected.not_to have_text(person.to_s)
        end.to(change { person.reload.encrypted_password })
      end
    end

    context 'person with login' do
      let(:person) do
        person = people(:bottom_member)
        person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: 'something')
        person
      end

      it 'should require at least 12 characters' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: 'test'
          fill_in 'Neues Passwort bestätigen', with: 'test'
          click_button 'Passwort ändern'
          is_expected.to have_text('Passwort ist zu kurz (weniger als 12 Zeichen)')
        end.not_to(change { person.reload.encrypted_password })
      end

      it 'should not be signed in automatically after password reset' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: password
          fill_in 'Neues Passwort bestätigen', with: password
          click_button 'Passwort ändern'
          is_expected.to have_text('Anmelden')
          is_expected.not_to have_text(person.to_s)
        end.to(change { person.reload.encrypted_password })
      end
    end

    context 'person with login and 2FA' do
      let(:person) do
        person = people(:bottom_member)
        person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: 'something', encrypted_two_fa_secret: 'something')
        person
      end

      it 'should require at least 12 characters' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: 'test'
          fill_in 'Neues Passwort bestätigen', with: 'test'
          click_button 'Passwort ändern'
          is_expected.to have_text('Passwort ist zu kurz (weniger als 12 Zeichen)')
        end.not_to(change { person.reload.encrypted_password })
      end

      # Ensure 2FA cannot be skipped
      it 'should not be signed in automatically after password reset' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: password
          fill_in 'Neues Passwort bestätigen', with: password
          click_button 'Passwort ändern'
          is_expected.to have_text('Anmelden')
          is_expected.not_to have_text(person.to_s)
        end.to(change { person.reload.encrypted_password })
      end
    end
  end

  context 'self-service password reset' do
    let(:link) { request_password_reset(person) }

    context 'person without login' do
      let(:person) do
        person = people(:bottom_member)
        person.update_columns(encrypted_password: nil)
        person
      end

      it 'should require at least 12 characters' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: 'test'
          fill_in 'Neues Passwort bestätigen', with: 'test'
          click_button 'Passwort ändern'
          is_expected.to have_text('Passwort ist zu kurz (weniger als 12 Zeichen)')
        end.not_to(change { person.reload.encrypted_password })
      end

      it 'should not be signed in automatically after password reset' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: password
          fill_in 'Neues Passwort bestätigen', with: password
          click_button 'Passwort ändern'
          is_expected.to have_text('Anmelden')
          is_expected.not_to have_text(person.to_s)
        end.to(change { person.reload.encrypted_password })
      end
    end

    context 'person with login' do
      let(:person) do
        person = people(:bottom_member)
        person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: 'something')
        person
      end

      it 'should require at least 12 characters' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: 'test'
          fill_in 'Neues Passwort bestätigen', with: 'test'
          click_button 'Passwort ändern'
          is_expected.to have_text('Passwort ist zu kurz (weniger als 12 Zeichen)')
        end.not_to(change { person.reload.encrypted_password })
      end

      it 'should not be signed in automatically after password reset' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: password
          fill_in 'Neues Passwort bestätigen', with: password
          click_button 'Passwort ändern'
          is_expected.to have_text('Anmelden')
          is_expected.not_to have_text(person.to_s)
        end.to(change { person.reload.encrypted_password })
      end
    end

    context 'person with login and 2FA' do
      let(:person) do
        person = people(:bottom_member)
        person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: 'something', encrypted_two_fa_secret: 'something')
        person
      end

      it 'should require at least 12 characters' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: 'test'
          fill_in 'Neues Passwort bestätigen', with: 'test'
          click_button 'Passwort ändern'
          is_expected.to have_text('Passwort ist zu kurz (weniger als 12 Zeichen)')
        end.not_to(change { person.reload.encrypted_password })
      end

      # Ensure 2FA cannot be skipped
      it 'should not be signed in automatically after password reset' do
        expect do
          visit link
          fill_in 'Neues Passwort', with: password
          fill_in 'Neues Passwort bestätigen', with: password
          click_button 'Passwort ändern'
          is_expected.to have_text('Anmelden')
          is_expected.not_to have_text(person.to_s)
        end.to(change { person.reload.encrypted_password })
      end
    end
  end

  def find_mail_to(email)
    ActionMailer::Base.deliveries.find { |mail|
      mail.to.include?(email)
    }
  end

  def click_send_login_button(person, me)
    Person::SendLoginJob.new(person, me).perform
    mail = find_mail_to(person.email)
    # Return the link sent in the mail
    mail.body.raw_source[/href=\"https?:\/\/[^\/]+(\/[^\"]*)/,1]
  end

  def request_password_reset(person)
    person.send_reset_password_instructions
    mail = find_mail_to(person.email)
    # Return the link sent in the mail
    mail.body.raw_source[/href=\"https?:\/\/[^\/]+(\/[^\"]*)/,1]
  end
end
