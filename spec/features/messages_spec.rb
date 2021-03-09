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
    messages = double
    allow(messages).to receive(:enable_writing).and_return(true)
    allow(Settings).to receive(:messages).and_return(messages)
  end

  before do
    sign_in
    visit group_mailing_list_messages_path(group_id: list.group.id, mailing_list_id: list.id)
  end

  context 'letter' do
    before do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      42.times do
        person = Fabricate(:person_with_address)
        Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
      end
    end

    it 'displays recipient info' do
      click_link('Brief erstellen')

      is_expected.to have_selector('a', text: 'Brief wird für 42 Personen erstellt.')
      is_expected.to have_text('(Eine Person hat keine vollständige Addresse hinterlegt.)')
    end
  end

  context 'text message' do
    before do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      42.times do
        person = Fabricate(:phone_number, label: 'Mobil').contactable
        Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
      end
    end

    it 'displays recipient info' do
      click_link('SMS erstellen')

      is_expected.to have_selector('a', text: 'SMS wird für 42 Personen erstellt.')
      is_expected.to have_text('(Eine Person hat keine vollständige Mobiltelefonnummer hinterlegt.)')
    end
  end

end
