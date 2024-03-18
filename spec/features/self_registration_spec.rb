# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

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

  describe 'multi step wizard navigation' do
    prepend_view_path Rails.root.join('spec', 'support', 'views')

    before do
      stub_const('SelfRegistration::MultiStep' ,Class.new(SelfRegistration) do
        self.partials = [:first_step, :second_step, :third_step]

        def first_step_valid? = true
        def second_step_valid? = true
        def third_step_valid? = main_person.valid?
      end)

      allow_any_instance_of(Groups::SelfRegistrationController).to receive(:entry) do |controller|
        controller.instance_eval do
          @entry ||= SelfRegistration::MultiStep.new(
          group: group,
          params: params.to_unsafe_h.deep_symbolize_keys
        )
        end
      end

      I18n.backend.store_translations :de, groups: {  self_registration: { form: {
        first_step_title: 'FirstStep',
        second_step_title: 'SecondStep',
        third_step_title: 'ThirdStep'
      } } }

      visit group_self_registration_path(group_id: group)
      click_on 'Weiter'
      click_on 'Weiter'
      complete_main_person_form
      assert_step 'ThirdStep'
    end

    def assert_step(step_name)
      expect(page).to have_css('.step-headers li.active', text: step_name),
                      "expected step '#{step_name}' to be active, but step '#{find('.step-headers li.active', wait: 0).text}' is active"
    end

    def click_on_breadcrumb(link_text)
      within('.step-headers') { click_on link_text }
    end

    it 'can go back and forth' do
      click_on 'Zurück'
      assert_step 'SecondStep'
      click_on 'Zurück'
      assert_step 'FirstStep'
      click_on 'Weiter'
      assert_step 'SecondStep'
      click_on 'Weiter'
      assert_step 'ThirdStep'
      click_on 'Zurück'
      assert_step 'SecondStep'
    end

    context 'when step is invalid' do
      before do
        allow_any_instance_of(SelfRegistration::MultiStep).
          to receive(:second_step_valid?).and_return(false)

        visit group_self_registration_path(group_id: group)
        click_on 'Weiter'
      end

      it 'can not continue' do
        click_on 'Weiter'
        assert_step 'SecondStep'
      end

      it 'can go back' do
        click_on 'Zurück'
        assert_step 'FirstStep'
      end
    end
  end
end
