# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'households/edit.html.haml' do
  let(:group) { Group.new(id: 1) }
  let(:person) do
    Person.new(id: 2, first_name: 'Max', last_name: 'Muster', address: 'Musterplatz',
               street: 'Musterstreet', housenumber: '10', zip_code: 1235, town: 'Mustertown')
  end

  let(:household) { Household.new(person) }
  let(:dom) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  before do
    controller.request.path_parameters[:group_id] = group.id
    controller.request.path_parameters[:person_id] = person.id
    allow(view).to receive(:person_home_path).and_return('')
    allow(view).to receive_messages(entry: household, person: person,
                                    parents: [group, person])
  end

  describe 'address info' do
    it 'renders info' do
      expect(dom).to have_css('strong', text: 'Alle Personen teilen sich dieselbe Adresse.')
      expect(dom).to have_css('address', text: '1235 Mustertown')
    end
  end

  describe 'messages' do
    it 'is empty without warnings or errors' do
      expect(dom).not_to have_css('.alert.alert-danger')
      expect(dom).not_to have_css('.alert.alert-warning')
    end

    it 'lists warnings if present' do
      household.warnings.add(:base, 'This is a warning')
      expect(dom).to have_css('.alert.alert-warning li', text: 'This is a warning')
    end

    it 'lists errors if present' do
      household.errors.add(:base, 'This is an error')
      expect(dom).to have_css('.alert.alert-danger li', text: 'This is an error')
    end

    it 'hides warnings if errors are present' do
      household.warnings.add(:base, 'This is a warning')
      household.errors.add(:base, 'This is an error')

      expect(dom).not_to have_css('.alert.alert-warning')
    end
  end

  describe 'members_table' do
    it 'lists members in sequence they are added' do
      household.add(Person.new(first_name: 'Maxine', last_name: 'Muster'))
      household.add(Person.new(first_name: 'Maxi', last_name: 'Muster'))
      expect(dom).to have_css('tr:nth-of-type(1)', text: 'Max Muster')
      expect(dom).to have_css('tr:nth-of-type(2)', text: 'Maxine Muster')
      expect(dom).to have_css('tr:nth-of-type(3)', text: 'Maxi Muster')
    end

    it 'includes members age if present' do
      travel_to(Date.new(2023, 7, 7))
      person.birthday = Date.new(2000, 1, 1)
      expect(dom).to have_css('tr:nth-of-type(1)', text: "Max Muster\n(23)")
    end

    it 'has remove link with parameter and cofirm alert' do
      household.add(Person.new(id: 3, first_name: 'Maxine', last_name: 'Muster'))
      household.add(Person.new(id: 4, first_name: 'Maxi', last_name: 'Muster'))
      expect(dom).to have_css('tr:nth-of-type(2) a', count: 2)
      remove_link = dom.first('tr:nth-of-type(2) a')
      expect(remove_link).to have_css('i.fa-trash-alt')
      expect(remove_link[:href]).to eq edit_group_person_household_path(member_ids: [2, 4])
      expect(remove_link[:'data-confirm']).to start_with('Wollen Sie diesen Eintrag')
    end

    it 'has disabled trash icon with tooltip if email is unconfirmed' do
      person.unconfirmed_email = 'test'
      expect(dom).to have_css('tr:nth-of-type(1) a', count: 1)

      icon = dom.find('tr:nth-of-type(1) i.fa-trash-alt')
      expect(icon.native[:title]).to eq 'Die E-Mail Adresse muss bestätigt werden, bevor ' \
                                        'die Person aus der Familie entfernt werden kann.'
    end
  end

  describe 'edit_form' do
    let(:form) { dom.find("form[action='#{edit_group_person_household_path}']") }
    let(:tom_select) { form.find_field('member_ids[]').native }

    it 'form has autosubmit enabled' do
      expect(form.native['data-controller']).to eq 'autosubmit'
    end

    it 'has hidden fields for all members' do
      household.add(Person.new(id: 3, first_name: 'Maxine', last_name: 'Muster'))
      expect(form).to have_field 'member_ids[]', type: :hidden, with: 2
      expect(form).to have_field 'member_ids[]', type: :hidden, with: 3
    end

    it 'has tom select field for adding new member' do
      expect(tom_select['autofocus']).to eq 'autofocus'
      expect(tom_select['data-action']).to eq 'autosubmit#save'
      expect(tom_select['data-controller']).to eq 'tom-select'
      expect(tom_select['data-tom-select-url-value']).to eq query_household_path(person_id: 2)
      expect(tom_select['data-tom-select-no-results-value']).to eq 'Keine Einträge gefunden.'
    end
  end

  describe 'update_form' do
    let(:form) { dom.find("form[action='#{group_person_household_path}']") }

    it 'has save button and cancel link' do
      person.save!
      expect(form).to have_button 'Speichern'
      expect(form).to have_link 'Abbrechen', href: group_person_path(id: person.id)
    end

    it 'disables save button when household is not valid' do
      household.add(Person.new(household_key: 'test-123'))
      expect(form).to have_button 'Speichern', disabled: true
    end
  end

end
