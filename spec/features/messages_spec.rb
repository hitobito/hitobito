# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe :messages, js: true do

  subject { page }
  let(:list) { mailing_lists(:leaders) }

  before do
    messages = double(:settings, enable_writing: true, personal_salutation: false)
    allow(Settings).to receive(:messages).and_return(messages)
  end

  before do
    sign_in
    visit group_mailing_list_messages_path(group_id: list.group.id, mailing_list_id: list.id)
  end

  context 'letter' do
    before do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      3.times do
        person = Fabricate(:person_with_address)
        Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
      end
    end

    it 'displays recipient info' do
      click_link('Brief erstellen')

      is_expected.to have_selector('a', text: 'Brief wird für 3 Personen erstellt.')
      is_expected.to have_text('(Eine Person hat keine vollständige Addresse hinterlegt.)')
    end
  end

  context 'text message' do
    before do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      3.times do
        person = Fabricate(:phone_number, label: 'Mobil').contactable
        Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
      end
    end

    it 'displays recipient info' do
      click_link('SMS erstellen')

      is_expected.to have_selector('a', text: 'SMS wird für 3 Personen erstellt.')
      is_expected.to have_text('(Eine Person hat keine vollständige Mobiltelefonnummer hinterlegt.)')
    end
  end

  context 'letter assignments' do
    let(:printer) do
      company = Fabricate(:company, email: 'printer@example.com')
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two), person: company)
      company
    end

    before do
      assignments_settings = double(:assignments_settings)
      allow(assignments_settings).to receive(:enabled).and_return(true)
      allow(assignments_settings).to receive(:default_assignee_email).and_return(printer.email)
      Settings.assignments = assignments_settings
    end

    before do
      Subscription.create!(mailing_list: list,
                           subscriber: groups(:top_group),
                           role_types: [Group::TopGroup::Leader])
      3.times do
        person = Fabricate(:person_with_address)
        Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
      end
    end

    it 'creates new letter and assignment' do
      click_link('Brief erstellen')

      is_expected.to have_selector('a', text: 'Brief wird für 3 Personen erstellt.')
      fill_in 'Betreff', with: 'Letter with love'
      fill_in_trix_editor 'message_body', with: Faker::Lorem.sentences.join
      expect do
        click_button('Speichern')
      end.to change { Message::Letter.count }.by(1)

      is_expected.to have_selector('a', text: 'Druckauftrag erstellen')
      click_link('Druckauftrag erstellen')

      is_expected.to have_text('Sobald der Druckauftrag erstellt wurde, kann der Brief nicht mehr bearbeitet werden.')
      fill_in 'Titel', with: 'Print print print!'
      fill_in 'Beschreibung', with: 'Paper: A4, portrait, extra thick'
      expect do
        all('button', text: 'Speichern').first.click
      end.to change { printer.assignments.count }.by(1)

      is_expected.to have_selector('a', text: 'Anhang')
      click_link('Anhang')

      is_expected.to have_selector('a', text: 'PDF anzeigen')
      is_expected.to have_selector('a', text: 'Druckauftrag anzeigen')
    end
  end
end
