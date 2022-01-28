# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Email verification', js: true do

  subject { page }
  let(:person) { people(:bottom_member) }
  let(:group) { person.groups.first }
  let(:password) { 'asdfasdfasdfasdf' }

  context 'person without login' do
    let(:me) { people(:top_leader) }
    let(:person) do
      person = people(:bottom_member)
      person.update_columns(confirmed_at: nil, encrypted_password: nil)
      person
    end

    before { sign_in(me) }

    it 'should not require confirmation when creating with email' do
      visit new_group_role_path(group_id: group.id)
      click_link 'Neue Person erfassen'
      fill_in 'role[new_person][first_name]', with: 'Test'
      fill_in 'role[new_person][last_name]', with: 'User'
      fill_in 'role[new_person][email]', with: 'someone@example.com'
      first(:button, 'Speichern').click
      is_expected.to have_text('wurde erfolgreich erstellt')
      is_expected.to have_field('Haupt-E-Mail', with: 'someone@example.com')
    end

    it 'should not require confirmation when updating email' do
      visit edit_group_person_path(group_id: group.id, id: person.id)
      fill_in 'E-Mail', with: 'test@example.com'
      expect do
        first(:button, 'Speichern').click
      end.to change { person.reload.email }.to('test@example.com')
      is_expected.not_to have_text('E-Mail-Adresse muss noch bestätigt werden')
    end
  end

  context 'person with login' do
    let(:me) { people(:top_leader) }
    let(:person) do
      person = people(:bottom_member)
      person.update_columns(confirmed_at: 1.hour.ago, encrypted_password: 'something')
      person
    end

    before { sign_in(me) }

    it 'should send confirmation email when updating email' do
      visit edit_group_person_path(group_id: group.id, id: person.id)
      fill_in 'E-Mail', with: 'test@example.com'
      expect do
        first(:button, 'Speichern').click
      end.not_to change { person.reload.email }
      is_expected.to have_text('E-Mail-Adresse muss noch bestätigt werden')
    end
  end

  context 'unconfirmed person with login' do
    let(:person) do
      person = people(:bottom_member)
      person.update(password: password)
      person.update_columns(confirmed_at: nil)
      person
    end

    it 'should prevent logging in' do
      visit new_person_session_path
      fill_in 'person_email', with: person.email
      fill_in 'person_password', with: password
      click_button 'Anmelden'

      is_expected.to have_text('Du musst Deinen Account bestätigen, bevor Du fortfahren kannst.')
    end
  end

  context 'send_login' do
    let(:me) { people(:top_leader) }
    let(:person) do
      person = people(:bottom_member)
      person.update_columns(confirmed_at: nil)
      person
    end

    it 'should auto-confirm email' do
      link = click_send_login_button(person, me)
      expect do
        visit link
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      end.to change { person.reload.confirmed_at }.from(nil)
    end

    it 'should not auto-confirm email which has changed in the meantime' do
      link = click_send_login_button(person, me)
      person.update!(email: 'changed-email@example.com')
      expect do
        visit link
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      end.not_to change { person.reload.confirmed_at }.from(nil)
    end
  end

  context 'self-service password reset when unconfirmed' do
    let(:person) do
      person = people(:bottom_member)
      person.update_columns(confirmed_at: nil, unconfirmed_email: nil)
      person
    end

    it 'should auto-confirm email' do
      expect do
        token = person.generate_reset_password_token!
        visit edit_person_password_path(reset_password_token: token)
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      end.to change { person.reload.confirmed_at }.from(nil)
    end

    # Prevents the following scenario:
    # 1. Attacker has an email address which they control, but have never confirmed before
    # 2. Attacker requests a password reset email, but doesn't click the link yet
    # 3. Attacker has someone else change their email to one they don't control (or use a second account for it)
    # 4. The email change is effective immediately because no previous email was ever confirmed
    # 5. Attacker clicks the link from the password reset email and changes password. The new email must not be auto-confirmed.
    it 'should not auto-confirm email which has changed in the meantime' do
      expect do
        token = person.generate_reset_password_token!
        person.update!(email: 'other-email@example.com')
        visit edit_person_password_path(reset_password_token: token)
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      end.not_to change { person.reload.confirmed_at }.from(nil)
    end
  end

  context 'self-service password reset when pending reconfirmation' do
    let(:person) do
      person = people(:bottom_member)
      person.confirm
      person.update!(email: 'newmail@example.com')
      person.reload
    end

    # Prevents the following scenario:
    # 1. Attacker has a verified email address which they control
    # 2. Attacher changes email to an address which they don't own.
    #    Change is postponed, reconfirmation is pending
    # 3. Reconfirmation email is sent, but the attacker cannot receive it
    # 4. Attacker requests a password reset email, which is still sent to the old confirmed email
    # 5. Attacker changes password. The new email address must not be auto-confirmed.
    it 'should not auto-confirm email for security reasons' do
      expect do
        token = person.generate_reset_password_token!
        visit edit_person_password_path(reset_password_token: token)
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      end.not_to change { person.reload.email }
    end

    # Prevents the following scenario:
    # 1. Attacker has a verified email address which they control
    # 2. Attacker changes email to an address which they own. Change is
    #    postponed, reconfirmation is pending
    # 3. Attacker receives confirmation email, but doesn't click the link
    # 4. Attacker requests a password reset email, which is still sent to the old confirmed email
    # 5. Attacker changes email to an address which they don't own. Change is
    #    postponed, reconfirmation is pending
    # 6. Reconfirmation email is sent, but the attacker cannot receive it
    # 7. Attacker clicks the link from the password reset email and changes password.
    #    The new email must not be auto-confirmed.
    it 'should not auto-confirm email which has changed again in the meantime' do
      expect do
        token = person.generate_reset_password_token!
        person.update(email: 'other-email@example.com')
        visit edit_person_password_path(reset_password_token: token)
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      end.not_to change { person.reload.email }
    end
  end

  context 'self-service event registration' do
    let(:event) { events(:top_event) }

    before do
      event.update!(external_applications: true)
    end

    it 'should not confirm email' do
      visit register_group_event_path(group_id: event.groups.first.id, id: event.id)
      first('#new_person #person_email').fill_in with: 'newguy@example.com'
      click_button 'Weiter'
      is_expected.to have_text 'Bitte fülle das folgende Formular aus, bevor du dich für den Anlass anmeldest.'

      fill_in 'Vorname', with: 'New'
      fill_in 'Nachname', with: 'Guy'
      fill_in 'Haupt-E-Mail', with: 'newguy@example.com'
      first(:button, 'Speichern').click
      is_expected.to have_text 'Deine persönlichen Daten wurden aufgenommen.'

      click_button 'Anmelden'
      is_expected.to have_text 'newguy@example.com'
      expect(Person.find_by(email: 'newguy@example.com').confirmed?).to be_falsey
    end
  end

  context 'self-service group registration' do
    let(:group) { groups(:bottom_group_one_one) }

    before do
      group.update!(self_registration_role_type: Group::BottomGroup::Member.sti_name)
    end

    it 'should not auto-confirm email' do
      visit group_self_registration_path(group_id: group.id)
      fill_in 'Vorname', with: 'New'
      fill_in 'Nachname', with: 'Guy'
      fill_in 'Haupt-E-Mail', with: 'newguy@example.com'
      first(:button, 'Speichern').click
      is_expected.to have_text 'Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.'
      expect(Person.find_by(email: 'newguy@example.com').confirmed?).to be_falsey

      mail = find_mail_to('newguy@example.com')
      expect(mail.subject).to eq('Anleitung für das Setzen Deines Passworts')
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
end
