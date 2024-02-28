# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe :event_participation do

  subject { page }

  let(:person) { people(:top_leader) }
  let(:event) { Fabricate(:event, application_opening_at: 5.days.ago, groups: [group]) }
  let(:group) { groups(:bottom_layer_one) }

  before do
    sign_in(person)
  end

  context 'with privacy policies in hierarchy' do
    let(:top_layer) { groups(:top_layer) }

    before do
      file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                     filename: 'logo.png',
                                                     content_type: 'image/png').signed_id
      top_layer.layer_group.update(privacy_policy: image,
                                   privacy_policy_title: 'Privacy Policy Top Layer')
      group.update(privacy_policy: image,
                   privacy_policy_title: 'Additional Policies Bottom Layer')
    end

    it 'creates an event participation if privacy policy is accepted' do
      visit group_event_path(group_id: group, id: event)

      click_link('Anmelden')

      is_expected.to have_content('Privacy Policy Top Layer')
      is_expected.to have_content('Additional Policies Bottom Layer')

      find('input#event_participation_contact_data_privacy_policy_accepted').click

      find_all('.bottom .btn-group button[type="submit"]').first.click # "Weiter"

      expect do
        click_button('Anmelden')
        is_expected.to have_text(
          "Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. " \
          'Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an.'
        )
      end.to change { Event::Participation.count }.by(1)

      participation = Event::Participation.find_by(event: event, person: person)

      expect(participation).to be_present
    end

    it 'does not create an event participation if privacy policy is not accepted' do
      visit group_event_path(group_id: group, id: event)

      click_link('Anmelden')

      expect(current_path).to eq(contact_data_group_event_participations_path(group, event))

      is_expected.to have_content('Privacy Policy Top Layer')
      is_expected.to have_content('Additional Policies Bottom Layer')

      find_all('.bottom .btn-group button[type="submit"]').first.click # "Weiter"

      expect(current_path).to eq(contact_data_group_event_participations_path(group, event))
    end
  end
end
