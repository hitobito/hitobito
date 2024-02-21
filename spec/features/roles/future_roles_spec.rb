# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Future Roles behaviour', js: :true do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer) { groups(:bottom_layer_one) }
  let(:role_type) { Group::TopGroup::Member.sti_name }
  let(:tomorrow) { Time.zone.tomorrow }
  let(:yesterday) { Time.zone.yesterday }

  let(:current_roles_aside) { 'section:nth-of-type(2)' }
  let(:future_roles_aside) { 'section:nth-of-type(3)' }

  before { sign_in(top_leader) }

  def create_future_role(person: bottom_member, group: top_group, type: role_type,
                         convert_on: tomorrow)
    Fabricate(:role, type: FutureRole.sti_name, person: person, group: group,
                     convert_on: convert_on, convert_to: type)
  end

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

    it 'creates destroyed role when bis is in the past' do
      visit group_person_path(bottom_layer, bottom_member, locale: :de)

      click_on 'Rolle hinzufügen'
      choose_role 'Member'
      fill_in 'Von', with: yesterday - 3.months
      fill_in 'Bis', with: yesterday
      expect do
        first(:button, 'Speichern').click
        expect(page).to have_content "Rolle Member (bis #{I18n.l(yesterday)}) für Bottom Member in " \
          'Bottom One wurde erfolgreich gelöscht.'
      end.to change { bottom_member.roles.with_deleted.count }.by(1)
    end
  end

  describe 'group bottom_members list' do
    it 'hides pill if no future roles exist' do
      visit group_people_path(top_group, locale: :de)
      expect(page).not_to have_link 'Zukünftige'
    end

    it 'lists future roles in seperate pill' do
      create_future_role
      visit group_people_path(top_group, locale: :de)
      expect(page).not_to have_link 'Member Bottom'
      expect(page).to have_link 'Zukünftige (1)'

      click_on 'Zukünftige (1)'
      expect(page).to have_link 'Member Bottom'
      expect(page).to have_content "Member (ab #{I18n.l(tomorrow)})"
    end

    describe 'filter' do
      it 'does not list future role type in roles filter' do
        visit new_group_people_filter_path(top_group, locale: :de)
        click_on 'Rollen'

        # Counts are without future role
        expect(page).to have_css('#roles .same-layer .checkbox.inline', count: 8)
        expect(page).to have_css('#roles .same-group .checkbox.inline', count: 6)
      end
    end
  end

  describe 'showing future roles' do
    describe 'people show' do
      it 'lists future roles in seperate section' do
        create_future_role
        visit group_person_path(bottom_layer, bottom_member, locale: :de)
        expect(page).to have_css "#{future_roles_aside} h2", text: 'Zukünftige Rollen'
        expect(page).to have_css future_roles_aside,
                                 text: "Top / TopGroup\nMember (ab #{I18n.l(tomorrow)})"

        within(current_roles_aside) { expect(page).to have_link 'Hauptgruppe setzen' }
        within(future_roles_aside) { expect(page).not_to have_link 'Hauptgruppe setzen' }
      end

      it 'does not show section if no future roles exist' do
        visit group_person_path(bottom_layer, bottom_member, locale: :de)
        expect(page).not_to have_text 'Zukünftige Rollen'
      end
    end
  end

  describe 'person history' do
    let(:role) { roles(:bottom_member) }

    it 'lists future roles in separate section' do
      create_future_role
      visit history_group_person_path(role.group, role.person, locale: :de)
      expect(page).to have_css 'h2', text: 'Zukünftige Rollen'
      expect(page).to have_text "Top / TopGroup Member #{I18n.l(tomorrow)}"
    end

    it 'does show inactive roles in separate section' do
      Fabricate(Group::BottomLayer::Leader.sti_name, person: role.person, group: role.group)
      role.update_columns(deleted_at: 3.days.ago)
      visit history_group_person_path(role.group, role.person, locale: :de)
      expect(page).to have_css 'h2', text: 'Inaktive Rollen'
      expect(page).to have_text 'Bottom One Member'
    end

    it 'does only show those sections if roles exist' do
      visit history_group_person_path(role.group, role.person, locale: :de)
      expect(page).not_to have_css 'h2', text: 'Zukünftige Rollen'
      expect(page).not_to have_css 'h2', text: 'Inaktive Rollen'
    end
  end


  describe 'versions', versioning: true do
    before { create_future_role }

    it 'lists future role in person log' do
      visit log_group_person_path(bottom_layer, bottom_member, locale: :de)
      expect(page).to have_content "Rolle Member (ab #{I18n.l(tomorrow)}) wurde hinzugefügt"
    end

    it 'lists future role in group log' do
      visit log_group_person_path(bottom_layer, bottom_member, locale: :de)
      expect(page).to have_content "Rolle Member (ab #{I18n.l(tomorrow)}) wurde hinzugefügt"
    end
  end

  describe 'managing future roles' do
    def existing_role_attrs
      bottom_member.roles.find_by(type: 'FutureRole').attributes.symbolize_keys
    end

    def choose_role(role, current_selection: nil)
      expect(page).to have_css('#role_type_select #role_type')
      find('#role_type_select #role_type').click
      expect(page).to have_css('#role_type_select #role_type option', text: role)
      find('#role_type_select #role_type').find('option', text: role).click
    end

    def deselect_role
      expect(page).to have_css('#role_type_select #role_type')
      find('#role_type_select #role_type').click
      expect(page).to have_css('#role_type_select #role_type option', text: '')
      find('#role_type_select #role_type').find_all('option', text: '').first.click
    end

    it 'can create new future role' do
      visit group_person_path(bottom_layer, bottom_member, locale: :de)

      click_on 'Rolle hinzufügen'
      choose_role 'Member'
      fill_in 'Von', with: tomorrow
      expect do
        first(:button, 'Speichern').click
        expect(page).to have_content "Rolle Member (ab #{I18n.l(tomorrow)}) für Bottom Member in " \
          'Bottom One wurde erfolgreich erstellt.'
      end.to change { bottom_member.roles.count }.by(1)

      role = bottom_member.roles.last
      expect(role.type).to eq FutureRole.sti_name
      expect(role.convert_to).to eq 'Group::BottomLayer::Member'
      expect(role.convert_on).to eq tomorrow
      expect(role.created_at.to_date).to eq Time.zone.today
    end

    it 'keeps start date when not selecting a role' do
      visit group_person_path(bottom_layer, bottom_member, locale: :de)
      click_on 'Rolle hinzufügen'
      fill_in 'Von', with: tomorrow
      deselect_role
      expect do
        first(:button, 'Speichern').click
      end.not_to(change { bottom_member.roles.count })
      expect(page).to have_css '.alert-danger', text: 'Rolle muss ausgefüllt werden'
      expect(page).to have_field('Von', with: I18n.l(tomorrow))
    end

    it 'can convert type of future role on people list' do
      create_future_role
      visit group_people_path(top_group, locale: :de)
      click_on 'Zukünftige (1)'
      expect(page).to have_css('a.nav-link.active', text: 'Zukünftige (1)')
      click_on 'Bearbeiten'
      choose_role 'Leader', current_selection: 'Member'
      expect do
        click_on 'Speichern'
        expect(page).not_to have_css '.popover'
        expect(page).to have_text 'Leader (ab'
      end.to change { existing_role_attrs[:convert_to] }
        .from(role_type).to('Group::TopGroup::Leader')
        .and(not_change { existing_role_attrs[:convert_on] })
    end

    it 'can convert future role to active role via person show page' do
      create_future_role
      visit group_person_path(bottom_layer, bottom_member, locale: :de)
      expect(page).to have_css("#{future_roles_aside} h2", text: 'Zukünftige Rollen')
      within(future_roles_aside) { click_on 'Bearbeiten' }
      fill_in 'Von', with: Time.zone.yesterday
      first(:button, 'Speichern').click
      expect(page).not_to have_text 'Zukünftige Rollen'
    end

    it 'cannot convert active role to future role' do
      visit group_person_path(bottom_layer, bottom_member, locale: :de)
      within(current_roles_aside) { click_on 'Bearbeiten' }
      fill_in 'Von', with: tomorrow
      first(:button, 'Speichern').click
      expect(page).to have_css '.alert-danger', text: 'Von kann nicht später als heute sein'
    end

    it 'saving outdated future role converts role' do
      role = create_future_role.tap { |r| r.update_columns(convert_on: yesterday) }
      visit edit_group_role_path(group_id: top_group.id, id: role.id, locale: :de)
      expect(page).to have_field 'Von', with: yesterday.strftime('%d.%m.%Y')
      first(:button, 'Speichern').click
      expect(page).not_to have_css '.roles', text: 'TopGroup / Member'
      expect(page).not_to have_css 'h2', text: 'Zukünftige Rollen'
    end
  end
end
