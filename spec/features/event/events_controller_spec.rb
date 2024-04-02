# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventsController, js: true do

  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk), groups: [groups(:top_group)])
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  context 'contacts' do
    NOTIFICATION_CHECKBOX_SELECTOR = '#event_notify_contact_on_participations'

    let(:edit_path) { edit_group_event_path(event.group_ids.first, event.id) }

    def notification_checkbox_visible(visible)
      have_checkbox = have_selector(NOTIFICATION_CHECKBOX_SELECTOR)
      visible ? expect(page).to(have_checkbox) : expect(page).not_to(have_checkbox)
    end

    def notification_checkbox
      find(NOTIFICATION_CHECKBOX_SELECTOR)
    end

    def click_save
      all('form .btn-group').first.click_button 'Speichern'
    end

    it 'may set and remove contact from event' do
      obsolete_node_safe do
        sign_in
        visit edit_path

        notification_checkbox_visible(false)

        # set contact
        fill_in 'Kontaktperson', with: 'Top'
        expect(find('ul[role="listbox"] li[role="option"]')).to have_content 'Top Leader'
        find('ul[role="listbox"] li[role="option"]').click
        find('body').send_keys(:tab) #unfocus input field
        notification_checkbox_visible(true)
        click_save

        # show event
        expect(find('aside')).to have_content 'Kontakt'
        expect(find('aside')).to have_content 'Top Leader'
        click_link 'Bearbeiten'
        notification_checkbox_visible(true)

        # remove contact
        expect(find('#event_contact').value).to eq('Top Leader')
        fill_in 'Kontaktperson', with: ''
        notification_checkbox_visible(false)
        click_save

        # show event again
        expect(page).to have_no_selector('.contactable')
      end
    end

    it 'toggles participation notifications' do
      event.update(contact: people(:top_leader))

      sign_in
      visit edit_path

      expect(notification_checkbox).not_to be_checked
      notification_checkbox.click
      click_save

      visit edit_path
      expect(notification_checkbox).to be_checked
    end
  end

  context 'standard course description gets updated from event kind' do
    let(:form_path) { new_group_event_path(event.group_ids.first, event.id, event: { type: Event::Course }, format: :html) }
    let(:prefill_description) { 'Test description' }

    before :each do
      sign_in
      visit form_path
    end

    it 'fills default description if empty' do
      obsolete_node_safe do
        select 'SLK (Scharleiterkurs)', from: 'event_kind_id'
        expect(find('#event_description').value).to eq event.kind.general_information
      end
    end


    it 'does not fill textarea' do
      obsolete_node_safe do
        fill_in 'event_description', with: prefill_description
        select 'SLK (Scharleiterkurs)', from: 'event_kind_id'
        expect(find('#event_description').value).to eq prefill_description
      end
    end
  end
end
