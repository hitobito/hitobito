# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
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
      cell.should have_text 'Member'
    end

    context 'without permission' do
      let(:user) { people(:bottom_member) }

      it 'does not render edit link' do
        cell.should_not have_link 'Bearbeiten'
      end
    end


    context 'with permission' do
      let(:user) { people(:top_leader) }
      before { within(cell) { click_link 'Bearbeiten' } }

      it 'cancel closes popover' do
        obsolete_node_safe do
          #find('#role_type_select a.chosen-single').click
          click_link 'Abbrechen'
          page.should_not have_css('.popover')
        end
      end

      it 'changes role' do
        obsolete_node_safe do
          find('#role_type_select a.chosen-single').click
          find('#role_type_select ul.chosen-results').find('li', text: 'Leader').click

          click_button 'Speichern'
          page.should_not have_css('.popover')
          cell.should have_text 'Leader'
        end
      end

      it 'changes role and group' do
        obsolete_node_safe do
          find('#role_group_id_chosen a.chosen-single').click
          find('#role_group_id_chosen ul.chosen-results').find('li', text: 'Group 111').click

          find('#role_type_select a.chosen-single').click
          find('#role_type_select ul.chosen-results').find('li', text: 'Leader').click
          click_button 'Speichern'
          cell.should have_text 'Group 111'
        end
      end

      it 'informs about missing type selection' do
        obsolete_node_safe do
          find('#role_group_id_chosen a.chosen-single').click
          find('#role_group_id_chosen ul.chosen-results').find('li', text: 'Group 111').click

          click_button 'Speichern'
          page.should have_selector('.popover .alert-error', text: 'Rolle muss ausgefüllt werden')

          find('#role_type_select a.chosen-single').click
          find('#role_type_select ul.chosen-results').find('li', text: 'Leader').click
          click_button 'Speichern'
          cell.should have_text 'Group 111'
        end
      end
    end
  end


  context 'people relations' do
    let(:user) { people(:top_leader) }

    it 'is not disabled if no predefined_labels are set' do
      sign_in(user)
      visit edit_group_person_path(group_id: groups(:top_group), id: user.id)

      should_not have_content 'Beziehungen'
    end

    context 'with predefined labels' do

      before do
        Settings.people_relation = OpenStruct.new(predefined_labels: ['test'])

        sign_in(user)
        visit edit_group_person_path(group_id: groups(:top_group), id: user.id)
      end

      it 'can define a new relation to himself' do
        obsolete_node_safe do
          should have_content 'Beziehungen'

          find('a[data-association="people_relations"]', text: 'Eintrag hinzufügen').click
          find('input[data-provide=entity]').set('Top')
          find('ul.typeahead li').click

          all('button', text: 'Speichern').first.click
          user.people_relations.should have(1).item
        end
      end

      pending 'remove existing relation'
    end
  end
end

