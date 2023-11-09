require 'spec_helper'

describe 'Future Roles behaviour' do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer) { groups(:bottom_layer_one) }
  let(:role_type) { Group::TopGroup::Member.sti_name }
  let(:tomorrow) { Time.zone.tomorrow }

  let(:current_roles_aside) { 'section:nth-of-type(2)' }
  let(:future_roles_aside) { 'section:nth-of-type(3)' }

  before do
    sign_in(top_leader)
    Capybara.default_max_wait_time = 0.5
  end

  def create_future_role(person: bottom_member, group: top_group, type: role_type, convert_on: tomorrow)
    Fabricate(:role, type: FutureRole.sti_name, person: person, group: group, convert_on: convert_on, convert_to: type)
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
        expect(page).to have_css future_roles_aside, text: "Top / TopGroup\nMember (ab #{I18n.l(tomorrow)})"
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
      expect(page).to have_text "Top / TopGroup Member (ab #{I18n.l(tomorrow)}) #{I18n.l(tomorrow)}"
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
      find('#role_type_select a.chosen-single').click
      expect(page).to have_css('#role_type_select a.chosen-single > span', text: current_selection)
      find('#role_type_select ul.chosen-results').find('li', text: role).click
    end

    def deselect_role
      find('.search-choice-close').click
    end

    it 'can create new future role', :js do
      visit group_person_path(bottom_layer, bottom_member, locale: :de)

      click_on 'Rolle hinzufügen'
      choose_role 'Member'
      fill_in 'Von', with: tomorrow
      expect do
        first(:button, 'Speichern').click
      end.to change { bottom_member.roles.count }.by(1)

      role = bottom_member.roles.last
      expect(role.type).to eq FutureRole.sti_name
      expect(role.convert_to).to eq 'Group::BottomLayer::Member'
      expect(role.convert_on).to eq tomorrow
      expect(role.created_at.to_date).to eq Time.zone.today
    end

    it 'keeps start date when not selecting a role', :js do
      visit group_person_path(bottom_layer, bottom_member, locale: :de)
      click_on 'Rolle hinzufügen'
      fill_in 'Von', with: tomorrow
      deselect_role
      expect do
        first(:button, 'Speichern').click
      end.not_to change { bottom_member.roles.count }
      expect(page).to have_css '.alert-error', text: 'Rolle muss ausgefüllt werden'
      expect(page).to have_field('Von', with: I18n.l(tomorrow))
    end

    it 'can convert type of future role on people list', :js do
      create_future_role
      visit group_people_path(top_group, locale: :de)
      click_on 'Zukünftige (1)'
      expect(page).to have_css('li.active', text: 'Zukünftige (1)')
      click_on 'Bearbeiten'
      choose_role 'Leader', current_selection: 'Member'
      expect do
        click_on 'Speichern'
        expect(page).not_to have_css '.popover'
      end.to change { existing_role_attrs[:convert_to] }
        .from(role_type).to('Group::TopGroup::Leader')
        .and not_change { existing_role_attrs[:convert_on] }
    end

    it 'can convert future role to active role via person show page', :js do
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
      expect(page).to have_css '.alert-error', text: 'Von kann nicht später als heute sein'
    end
  end
end
