# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Email verification', js: true do

  subject { page }
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
      fill_in 'role[new_person][email]', with: 'someone@puzzle.ch'
      first(:button, 'Speichern').click
      is_expected.to have_text('wurde erfolgreich erstellt')
      is_expected.to have_field('Haupt-E-Mail', with: 'someone@puzzle.ch')
    end

    it 'should not require confirmation when updating email' do
      visit edit_group_person_path(group_id: group.id, id: person.id)
      fill_in 'E-Mail', with: 'test@puzzle.ch'
      expect do
        first(:button, 'Speichern').click
      end.to change { person.reload.email }.to('test@puzzle.ch')
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
      fill_in 'E-Mail', with: 'test@puzzle.ch'
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
      fill_in 'Haupt-E-Mail', with: person.email
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
      expect {
        visit link
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      }.to change { person.reload.confirmed_at }.from(nil)
    end

    it 'should not auto-confirm email which has changed in the meantime' do
      link = click_send_login_button(person, me)
      person.update(email: 'changed-email@puzzle.ch')
      expect {
        visit link
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      }.not_to change { person.reload.confirmed_at }.from(nil)
    end
  end

  context 'self-service password reset' do
    let(:person) { people(:bottom_member) }

    it 'should auto-confirm email' do
      expect {
        token = person.generate_reset_password_token!
        visit edit_person_password_path(reset_password_token: token)
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      }.to change { person.reload.confirmed_at }.from(nil)
    end

    it 'should not auto-confirm email which has changed in the meantime' do
      expect {
        token = person.generate_reset_password_token!
        person.update(email: 'other-email@puzzle.ch')
        visit edit_person_password_path(reset_password_token: token)
        fill_in 'Neues Passwort', with: password
        fill_in 'Neues Passwort bestätigen', with: password
        click_button 'Passwort ändern'
      }.not_to change { person.reload.confirmed_at }.from(nil)
    end
  end

  context 'self-service event registration' do
    it 'should auto-confirm email' do
      # TODO
    end

    it 'should not auto-confirm email which has changed in the meantime' do
      # TODO
    end
  end

  context 'self-service group registration' do
    it 'should auto-confirm email' do
      # TODO
    end

    it 'should not auto-confirm email which has changed in the meantime' do
      # TODO
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
