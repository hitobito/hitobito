# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe HouseholdsController, js: true do
  let(:person) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:household) { Household.new(person) }

  before { sign_in(person) }

  it 'can add person to household' do
    visit edit_group_person_household_path(groups(:top_group).id, person.id)
    expect(page).to have_css('h1', text: 'Haushalt verwalten')
    fill_in 'household_add-ts-control', with: 'Bottom'
    find('span.highlight', text: 'Bottom').click
    expect(page).to have_css '.alert-warning', text: "Die Adresse 'Greatstreet 345, 3456 Greattown' wird für alle"
    expect do
      click_on 'Speichern'
      expect(page).to have_text 'Haushalt wurde erfolgreich aktualisiert.'
    end.to change { household.reload.members.count }.by(1)
  end

  it 'can navigate to a person from the household' do
    visit edit_group_person_household_path(groups(:top_group).id, person.id)
    within('#edit_household') do
      click_link(person.to_s)
    end
    expect(page).to have_current_path(group_person_path(groups(:top_group).id, person.id))
  end

  it 'can remove person from household' do
    household.add(bottom_member)
    expect(household.save).to eq true
    visit edit_group_person_household_path(groups(:top_group).id, person.id)
    accept_confirm { all('table i.fa-trash-alt')[1].click }
    expect(page).to have_text 'Der Haushalt wird aufgelöst da weniger als 2 Personen ' \
                              'vorhanden sind.'
    expect do
      click_on 'Speichern'
      expect(page).to have_text 'Haushalt wurde erfolgreich gelöscht.'
    end.to change { person.reload.household_key }.to(nil)
  end
end
