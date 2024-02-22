# encoding: utf-8

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.


require 'spec_helper'


describe PeopleController, js: true do

  subject { page }

  context 'inline editing of role' do
    let(:group) { groups(:bottom_layer_one) }
    let(:row)   { find('#content table.table').all('tr').find { |row| row.text =~ /Member Bottom/ } }
    let(:cell)  { row.all('td')[2] }

    before do
      sign_in(user)
      visit group_people_path(group_id: group.id)
      expect(cell).to have_text 'Member'
    end

    context 'without permission' do
      let(:user) { people(:bottom_member) }

      it 'does not render edit link' do
        expect(cell).to have_no_link 'Bearbeiten'
      end
    end


    context 'with permission' do
      let(:user) { people(:top_leader) }
      before { within(cell) { skip "Unable to find Bearbeiten"; click_link 'Bearbeiten' } }

      it 'cancel closes popover' do
        obsolete_node_safe do
          click_link 'Abbrechen'
          expect(page).to have_no_css('.popover')
        end
      end

      it 'changes role' do
        obsolete_node_safe do
          find('#role_type_select #role_type').click
          find('#role_type_select #role_type').find('option', text: 'Leader').click

          click_button 'Speichern'
          expect(page).to have_no_css('.popover')
          expect(cell).to have_text 'Leader'
        end
      end

      it 'changes role and group' do
        obsolete_node_safe do
          find('#role_group_id_chosen #role_type').click
          find('#role_group_id_chosen #role_type').find('option', text: 'Group 111').click

          find('#role_type_select #role_type').click
          find('#role_type_select #role_type').find('option', text: 'Leader').click
          click_button 'Speichern'
          expect(cell).to have_text 'Group 111'
        end
      end

      it 'informs about missing type selection' do
        obsolete_node_safe do
          find('#role_group_id_chosen #role_type').click
          find('#role_group_id_chosen #role_type').find('option', text: 'Group 111').click
          fill_in('role_label', with: 'dummy')

          click_button 'Speichern'
          expect(page).to have_selector('.popover .alert-danger', text: 'Rolle muss ausgefüllt werden')

          find('#role_type_select #role_type').click
          find('#role_type_select #role_type').find('option', text: 'Leader').click
          click_button 'Speichern'
          expect(cell).to have_text 'Group 111'
        end
      end
    end
  end


  context 'people relations' do
    let(:user) { people(:top_leader) }

    it 'is not disabled if no kinds are set' do
      sign_in(user)
      visit edit_group_person_path(group_id: groups(:top_group), id: user.id)

      expect(page).to have_no_content 'Beziehungen'
    end

    context 'with kinds and existing relations' do
      let(:relations) { Person.find(user.id).relations_to_tails }

      before do
        PeopleRelation.kind_opposites['sibling'] = 'sibling'
        relations.create!(tail_id: people(:bottom_member).id, kind: 'sibling')
        sign_in(user)
      end

      after do
        PeopleRelation.kind_opposites.clear
      end

      it 'can define a new relation' do
        obsolete_node_safe do
          visit edit_group_person_path(group_id: groups(:top_group), id: user.id)
          is_expected.to have_content 'Beziehungen'

          expect do
            expect(page).to have_selector('a[data-association="relations_to_tails"]')
            find('a[data-association="relations_to_tails"]', text: 'Eintrag hinzufügen').click
            find('#relations_to_tails_fields input[data-provide=entity]').set('Bottom')
            find('#relations_to_tails_fields ul[role="listbox"] li[role="option"]').click

            all('button', text: 'Speichern').first.click
            expect(page).to have_content('erfolgreich aktualisiert')
          end.to change { relations.size }.by(1)

          expect(relations.first.opposite.tail_id).to eq(user.id)
        end
      end

      it 'remove existing relation' do
        obsolete_node_safe do
          user.relations_to_tails.create!(tail_id: people(:bottom_member).id, kind: 'sibling')

          visit edit_group_person_path(group_id: groups(:top_group), id: user.id)
          is_expected.to have_content 'Beziehungen'

          expect do
            expect(page).to have_selector('#relations_to_tails_fields .remove_nested_fields')
            all('#relations_to_tails_fields .remove_nested_fields').first.click

            all('button', text: 'Speichern').first.click
            expect(page).to have_content('erfolgreich aktualisiert')

          end.to change { relations.size }.by(-1)
        end
      end
    end
  end

  context 'household' do
    let(:user) { people(:top_leader) }
    let(:person) { people(:bottom_member) }

    def create_person(first_name, household_key: nil)
      Fabricate(:person, first_name: first_name, household_key: household_key, roles: [
        Fabricate.build(Group::BottomLayer::Member.sti_name, group: person.primary_group)
      ])
    end

    def household_key_people_container = find('.household_key_people', visible: false)

    before { sign_in(user) }

    it 'can create a new household' do
      expect(person.household_key).to be_blank
      prospective_housemate = create_person('Prospective Housemate')

      visit edit_group_person_path(group_id: person.primary_group_id, id: person.id)
      expect(page).to have_field('household', checked: false)
      expect(page).to have_no_field('household_query')
      expect(household_key_people_container).to have_no_field(type: :hidden)

      check('household')
      expect(page).to have_field('household_query')

      fill_in('household_query', with: prospective_housemate.first_name)
      find('#autoComplete_result_0').click
      expect(household_key_people_container).to have_field(type: :hidden, count: 1)

      click_on('Speichern', match: :first)
      expect(page).to have_selector('.alert-success', text: /erfolgreich aktualisiert/)

      expect(person.reload.household_people).to contain_exactly(prospective_housemate)
    end

    it 'can add a person to a household' do
      person.update!(household_key: 'my-household')
      housemate = create_person('Housemate', household_key: 'my-household')

      prospective_housemate = create_person('Prospective Housemate')

      visit edit_group_person_path(group_id: person.primary_group_id, id: person.id)
      expect(page).to have_field('household', checked: true)
      expect(page).to have_field('household_query')
      expect(household_key_people_container).to have_field(type: :hidden, count: 1)

      fill_in('household_query', with: prospective_housemate.first_name)
      find('#autoComplete_result_0').click
      expect(household_key_people_container).to have_field(type: :hidden, count: 2)

      click_on('Speichern', match: :first)
      expect(page).to have_selector('.alert-success', text: /erfolgreich aktualisiert/)

      expect(person.household_people).to contain_exactly(housemate, prospective_housemate)
    end

    it 'can leave a household' do
      person.update!(household_key: 'my-household')
      housemate1 = create_person('Housemate1', household_key: 'my-household')
      housemate2 = create_person('Housemate2', household_key: 'my-household')

      visit edit_group_person_path(group_id: person.primary_group_id, id: person.id)
      expect(page).to have_field('household', checked: true)
      expect(page).to have_field('household_query')
      expect(household_key_people_container).to have_field(type: :hidden, count: 2)

      uncheck('household')
      expect(household_key_people_container).to have_no_field(type: :hidden)
      expect(household_key_people_container).to have_field(type: :hidden, disabled: true, count: 2)

      click_on('Speichern', match: :first)
      expect(page).to have_selector('.alert-success', text: /erfolgreich aktualisiert/)

      expect(person.reload.household_key).to be_nil
      expect(person.household_people).to be_empty

      expect(housemate1.household_people).to contain_exactly(housemate2)
    end

    it 'can dissolve a household' do
      person.update!(household_key: 'my-household')
      housemate = create_person('Housemate', household_key: 'my-household')

      visit edit_group_person_path(group_id: person.primary_group_id, id: person.id)
      expect(page).to have_field('household', checked: true)
      expect(page).to have_field('household_query')
      expect(household_key_people_container).to have_field(type: :hidden, count: 1)

      uncheck('household')
      expect(household_key_people_container).to have_no_field(type: :hidden)
      expect(household_key_people_container).to have_field(type: :hidden, disabled: true, count: 1)

      click_on('Speichern', match: :first)
      expect(page).to have_selector('.alert-success', text: /erfolgreich aktualisiert/)

      expect(person.reload.household_key).to be_nil
      expect(housemate.reload.household_key).to be_nil
    end
  end
end
