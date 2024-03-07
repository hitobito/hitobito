# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

# a group to test self-registration
class Group::SelfRegistrationGroup < Group
  self.layer = true

  # a suitable role to register as
  class ReadOnly < ::Role
    self.permissions = [:group_read]
  end

  roles ReadOnly
end

describe :self_registration, js: true do
  let(:group) { groups(:top_group) }

  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def complete_main_person_form
    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
  end

  describe 'main_person' do
    it 'validates required fields' do
      visit group_self_registration_path(group_id: group)
      click_on 'Registrieren'
      expect(page.find_field('Vorname')[:class]).to include('is-invalid')
    end

    it 'self registers and creates new person' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form

      expect { click_on 'Registrieren' }
        .to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text(
        'Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine ' \
        'E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.'
      )

      person = Person.find_by(email: 'max.muster@hitobito.example.com')
      expect(person).to be_present
      expect(person.first_name).to eq 'Max'
      expect(person.last_name).to eq 'Muster'
      person.confirm # confirm email

      person.password = person.password_confirmation = 'really_b4dPassw0rD'
      person.save!

      fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
      fill_in 'Passwort', with: 'really_b4dPassw0rD'

      click_button 'Anmelden'

      expect(person.roles.map(&:type)).to eq([self_registration_role.to_s])
      expect(current_path).to eq("#{group_person_path(group_id: group, id: person)}.html")
    end

    describe 'with adult consent' do
      let(:adult_consent_field) { page.find_field(adult_consent_text) }
      let(:adult_consent_text) do
        'Ich bestätige, dass ich mindestens 18 Jahre alt bin oder ' \
          'das Einverständnis meiner Erziehungsberechtigten habe.'
      end

      before do
        group.update!(self_registration_require_adult_consent: true)
        visit group_self_registration_path(group_id: group)
      end

      it 'cannot complete without accepting adult consent' do
        complete_main_person_form

        expect { click_on 'Registrieren' }.not_to(change { Person.count })
        expect(adult_consent_field.native.attribute('validationMessage'))
          .to eq 'Please check this box if you want to proceed.'
      end

      it 'can complete when accepting adult consent' do
        complete_main_person_form
        check adult_consent_text
        expect { click_on 'Registrieren' }.to change { Person.count }.by(1)
      end
    end

    describe 'with privacy policy' do
      before do
        file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
        image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                       filename: 'logo.png',
                                                       content_type: 'image/png').signed_id
        group.layer_group.update(privacy_policy: image)
        visit group_self_registration_path(group_id: group)
      end

      it 'sets privacy policy accepted' do
        complete_main_person_form

        check 'Ich erkläre mich mit den folgenden Bestimmungen einverstanden:'
        expect do
          click_on 'Registrieren'
        end.to change { Person.count }.by(1)
        person = Person.find_by(email: 'max.muster@hitobito.example.com')
        expect(person.privacy_policy_accepted).to eq true
      end

      it 'fails if private policy is not accepted' do
        complete_main_person_form
        expect do
          click_on 'Registrieren'
        end.not_to(change { Person.count })

        field = page.find_field('Ich erkläre mich mit den folgenden Bestimmungen einverstanden:')
        expect(field.native.attribute('validationMessage'))
          .to eq 'Please check this box if you want to proceed.'

        # flash not rendered because of native html require
        expect(page).not_to have_text(
          'Um die Registrierung abzuschliessen, muss der Datenschutzerklärung zugestimmt werden.'
        )
      end
    end

    it 'keyboard submit works' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form

      expect { send_keys(:return) }
        .to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text(
        'Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine ' \
        'E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.'
      )
    end
  end
end
