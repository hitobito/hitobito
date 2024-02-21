# frozen_string_literal: true

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe RolesController, js: true do

  subject { page }
  let(:group) { groups(:top_group) }
  let!(:role1)  { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
  let!(:role2)  { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
  let!(:leader) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group) }

  def choose_role(role, current_selection: nil)
    expect(page).to have_css('#role_type_select #role_type')
    find('#role_type_select #role_type').click
    expect(page).to have_css('#role_type_select #role_type option', text: role)
    find('#role_type_select #role_type').find('option', text: role).click
  end

  describe 'create' do
    let(:bottom_member) { people(:bottom_member) }
    let(:bottom_layer) { groups(:bottom_layer_one) }
    let(:yesterday) { Time.zone.yesterday }
    let(:top_leader) { people(:top_leader) }

    before do
      sign_in(top_leader)
      visit group_person_path(group_id: bottom_layer.id, id: bottom_member.id)
      click_on 'Rolle hinzufügen'
      choose_role 'Member'
    end

    it 'soft deletes role if bis in the past' do
      fill_in 'Von', with: yesterday - 3.months
      fill_in 'Bis', with: yesterday
      expect do
        first(:button, 'Speichern').click
        expect(page).to have_content "Rolle Member (bis #{I18n.l(yesterday)}) für Bottom Member in " \
          'Bottom One wurde erfolgreich gelöscht.'
      end.to change { bottom_member.roles.with_deleted.count }.by(1)
    end

    it 'hard deletes role if bis in the past and not valid for archive' do
      fill_in 'Von', with: yesterday - 1.day
      fill_in 'Bis', with: yesterday
      expect do
        first(:button, 'Speichern').click
      end.to not_change { bottom_member.roles.with_deleted.count }
        .and(not_change { bottom_member.roles.count })
      expect(page).to have_content "Rolle Member (bis #{I18n.l(yesterday)}) für Bottom Member in " \
        'Bottom One wurde erfolgreich gelöscht.'
    end

    it 'displays validation message if bis is before von' do
      fill_in 'Von', with: yesterday + 1.day
      fill_in 'Bis', with: yesterday

      expect do
        first(:button, 'Speichern').click
      end.to(not_change { bottom_member.roles.with_deleted.count })
      expect(page).to have_content 'Bis kann nicht vor Von sein'
      expect(page).to have_css('#role_delete_on.is-invalid')
    end
  end

  describe 'updating delete_on', js: false do
    let(:role) { roles(:bottom_member) }
    let(:tomorrow) { Time.zone.tomorrow }

    before { sign_in }

    it 'sets delete_on and rerenders' do
      visit edit_group_role_path(group_id: role.group_id, id: role.id)
      fill_in 'Bis', with: tomorrow
      all('form .bottom .btn-group').first.click_button 'Speichern'
      expect(page).to have_content "Rolle Member (bis #{tomorrow.strftime('%d.%m.%Y')}) für " \
        'Bottom Member in Bottom One wurde erfolgreich aktualisiert'
      expect(role.reload.delete_on).to eq tomorrow
    end

    it 'shows delete_on date' do
      role.update(delete_on: tomorrow)
      visit edit_group_role_path(group_id: role.group_id, id: role.id)
      expect(page).to have_field 'Bis', with: tomorrow.strftime('%d.%m.%Y')
    end

    it 'saving outdated role deletes role' do
      role.update_columns(created_at: 3.days.ago, delete_on: 1.day.ago.to_date)
      visit edit_group_role_path(group_id: role.group_id, id: role.id)
      expect do
        all('form .bottom .btn-group').first.click_button 'Speichern'
      end.to change { people(:bottom_member).roles.count }.by(-1)
    end
  end

  it 'toggles people fields' do
    obsolete_node_safe do
      sign_in
      visit new_group_role_path(group_id: group.id)
      is_expected.to have_content('Person hinzufügen')
      is_expected.to have_selector('#role_person', visible: true)
      is_expected.to have_selector('#role_new_person_first_name', visible: false)

      click_link('Neue Person erfassen')
      is_expected.to have_selector('#role_person', visible: false)
      is_expected.to have_selector('#role_new_person_first_name', visible: true)

      click_link('Bestehende Person suchen')
      is_expected.to have_selector('#role_person', visible: true)
      is_expected.to have_selector('#role_new_person_first_name', visible: false)
    end
  end

  it 'uses exisiting person when given' do
    obsolete_node_safe do
      sign_in
      visit new_group_role_path(group_id: group.id)

      expect(page).to have_css('#role_type_select #role_type')
      find('#role_type_select #role_type').click
      find('#role_type_select #role_type').find('option', text: 'Leader').click

      # test user clicking around first
      click_link('Neue Person erfassen')
      fill_in('Vorname', with: 'Tester')

      # now search existing person
      click_link('Bestehende Person suchen')
      fill_in 'Person', with: 'Top'
      page.find('ul[role="listbox"] li[role="option"]').click

      all('form .btn-group').first.click_button 'Speichern'
      is_expected.to have_content 'Rolle Leader für Top Leader in TopGroup wurde erfolgreich erstellt.'
      expect(current_path).to eq(group_people_path(group))
    end
  end

  it 'creates new person when fields filled' do
    obsolete_node_safe do
      sign_in
      visit new_group_role_path(group_id: group.id)

      find('#role_type_select #role_type').click
      find('#role_type_select #role_type').find('option', text: 'Leader').click

      # test user clicking around first
      fill_in 'Person', with: 'Top'
      sleep(0.5)
      find('ul[role="listbox"] li[role="option"]').click

      # now define new person
      click_link('Neue Person erfassen')
      fill_in('Vorname', with: 'Tester')

      all('form .btn-group').first.click_button 'Speichern'

      expect(current_path).not_to eq(group_people_path(group))
      is_expected.to have_content 'Rolle Leader für Tester in TopGroup wurde erfolgreich erstellt.'
    end
  end

  it 'updates info when type changes' do
    obsolete_node_safe do
      sign_in
      visit new_group_role_path(group_id: group.id)

      find('#role_type_select #role_type').click
      find('#role_type_select #role_type').find('option', text: 'Leader').click

      expect(find('#role_info')).to have_content('Die Rolle Leader in der Gruppe TopGroup')

      find('#role_type_select #role_type').click
      find('#role_type_select #role_type').find('option', text: 'Member').click

      expect(find('#role_info')).to have_content('Die Rolle Member in der Gruppe TopGroup')
    end
  end

  it 'updates role types when group changes' do
    obsolete_node_safe do
      sign_in
      visit new_group_role_path(group_id: group.id)

      # fill person
      fill_in 'Person', with: 'Top'
      page.find('ul[role="listbox"] li[role="option"]').click

      expect(all('#role_group_id option', visible: false).size).to eq(3)
      expect(all('#role_type option', visible: false).size).to eq(8)

      # select role that will be discarded
      find('#role_type_select #role_type').click
      find('#role_type_select #role_type').find('option', text: 'Leader').click

      # select group
      find('#role_group_id').click
      find('#role_group_id').find('option', text: 'Toppers').click

      expect(find('#role_type-ts-control')['placeholder']).to eq('Bitte auswählen')
      expect(all('#role_type option', visible: false).size).to eq(4)

      # select roleactiv
      find('.ts-control').click
      find('#role_type_select #role_type').find('option', text: 'Member').click

      expect(find('#role_info')).to have_content('Die Rolle Member in der Gruppe Toppers')

      # save
      all('form .btn-group').first.click_button 'Speichern'

      is_expected.to have_content 'Rolle Member für Top Leader in Toppers wurde erfolgreich erstellt.'
      expect(current_path).to eq(group_people_path(groups(:toppers)))
    end
  end

  it 'updates person role with popupmenu' do
    obsolete_node_safe do
      sign_in

      # Add additional role to first person
      visit group_people_path(group_id: group.id)
      find(:css, "#ids_[value='#{role1.person.id}']").set(true)
      find(:css, "#ids_[value='#{role2.person.id}']").set(true)

      find('.dropdown-toggle', text: 'Rollen').click
      find('a.dropdown-item', text: 'Rolle hinzufügen').click

      select('Leader', from: 'role_type')
      expect(page).to have_button '2 Rollen erstellen'
      find('button', text: '2 Rollen erstellen').click

      is_expected.to have_content('2 Rollen wurden erstellt')
      is_expected.to have_css("tr#person_#{role1.person.id} td p", text: 'Leader')
      is_expected.to have_css("tr#person_#{role2.person.id} td p", text: 'Leader')

      person_with_two_roles = role1.person
      person_with_two_roles_row = find("tr#person_#{person_with_two_roles.id}")

      # Expect to have people table with person above
      is_expected.to have_selector('div.table-responsive')
      is_expected.to have_css("tr#person_#{person_with_two_roles.id} td p", text: 'Leader')
      is_expected.to have_css("tr#person_#{person_with_two_roles.id} td p", text: 'Member')

      # Click person row to alter role of person and expect role popup
      person_with_two_roles_row.find_all('a[title="Bearbeiten"]').first.click
      is_expected.to have_css('div.popover')

      # Change role
      find('div.popover div#role_type_select').click
      is_expected.to have_css('div.popover option', visible: true)

      find('div.popover select#role_type').click
      all('div.popover option').last.click

      # Click save
      find('button[data-disable-with="Speichern"]').click

      # Expect role Leader and External
      is_expected.to have_css("tr#person_#{person_with_two_roles.id} td p", text: 'Leader')
      is_expected.to have_css("tr#person_#{person_with_two_roles.id} td p", text: 'External')

      # Expect role field to have no more roles than person has in db
      person_db_role_count = person_with_two_roles.roles.count
      expect(person_with_two_roles_row.find_all('td > p > span').count).to eq(person_db_role_count)
    end
  end

  context 'with privacy policies in hierarchy' do
    let(:bottom_layer) { groups(:bottom_layer_one) }

    before do
      file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                     filename: 'logo.png',
                                                     content_type: 'image/png').signed_id
      group.layer_group.update(privacy_policy: image,
                               privacy_policy_title: 'Privacy Policy Top Layer')
      bottom_layer.update(privacy_policy: image,
                          privacy_policy_title: 'Additional Policies Bottom Layer')
    end

    it 'creates person if privacy policy is accepted' do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group_id: bottom_layer.id)

        click_link('Neue Person erfassen')
        fill_in('Vorname', with: 'Tester')

        is_expected.to have_content('Privacy Policy Top Layer')
        is_expected.to have_content('Additional Policies Bottom Layer')

        find('input#role_new_person_privacy_policy_accepted').click

        all('form .btn-group').first.click_button 'Speichern'

        expect(current_path).not_to eq(group_people_path(bottom_layer))
        is_expected.to have_content 'Rolle Leader für Tester in Bottom One wurde erfolgreich erstellt.'
      end
    end
  end
end
