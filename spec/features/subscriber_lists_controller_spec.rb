# frozen_string_literal: true

#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::SubscriberListsController, js: true do

  subject { page }

  let(:group)   { groups(:top_group) }
  let!(:role1)  { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
  let!(:role2)  { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
  let!(:leader) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group) }
  let!(:list) { Fabricate(:mailing_list, name: 'Newsletter', group: group) }

  before do
    sign_in(people(:top_leader))
    visit group_people_path(group_id: group.id)
  end

  it 'adds to mailing list', js: true do
    find(:css, "#ids_[value='#{role1.person.id}']").set(true)
    find(:css, "#ids_[value='#{role2.person.id}']").set(true)

    click_link('Zu Abo hinzufügen')
    find('#q').fill_in with: 'News'
    sleep 0.5 # to avoid race condition in remote-typeahead
    dropdown = find('ul[role="listbox"]')
    expect(dropdown).to have_content('Newsletter')
    find('ul[role="listbox"] li[role="option"]', text: 'Newsletter').click

    expect do
      find('button', text: 'Hinzufügen').click
      expect(page).to have_content "2 Personen wurden erfolgreich zum Abo 'Newsletter' hinzugefügt"
    end.to change { Subscription.count }.by(2)

    is_expected.to have_text("2 Personen wurden erfolgreich zum Abo 'Newsletter' hinzugefügt")
  end
end
