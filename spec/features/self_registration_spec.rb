require 'spec_helper'

describe :self_registration do

  subject { page }

  let(:group) { groups(:bottom_layer_one) }
  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  context 'with privacy policies in hierarchy' do
    let(:top_layer) { groups(:top_layer) }

    before do
      file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                     filename: 'logo.png',
                                                     content_type: 'image/png').signed_id
      top_layer.layer_group.update(privacy_policy: image, privacy_policy_title: 'Privacy Policy Top Layer')
      group.update(privacy_policy: image, privacy_policy_title: 'Additional Policies Bottom Layer')
    end

    it 'self registers and creates new person if privacy policy is accepted' do
      visit group_self_registration_path(group_id: group)

      fill_in 'Vorname', with: 'Max'
      fill_in 'Nachname', with: 'Muster'
      fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'

      is_expected.to have_content('Privacy Policy Top Layer')
      is_expected.to have_content('Additional Policies Bottom Layer')

      find('input#role_new_person_privacy_policy_accepted').click

      expect do
        find_all('.btn-toolbar.bottom .btn-group button[type="submit"]').first.click # submit
      end.to change { Person.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      is_expected.to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

      person = Person.find_by(email: 'max.muster@hitobito.example.com')
      expect(person).to be_present

      person.confirm # confirm email

      person.password = person.password_confirmation = 'really_b4dPassw0rD'
      person.save!

      fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
      fill_in 'Passwort', with: 'really_b4dPassw0rD'

      click_button 'Anmelden'

      expect(person.roles.map(&:type)).to eq([self_registration_role.to_s])
      expect(current_path).to eq("#{group_person_path(group_id: group, id: person)}.html")
    end

    it 'does not self register if privacy policy is not accepted' do
      visit group_self_registration_path(group_id: group)

      fill_in 'Vorname', with: 'Max'
      fill_in 'Nachname', with: 'Muster'
      fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'

      is_expected.to have_content('Privacy Policy Top Layer')
      is_expected.to have_content('Additional Policies Bottom Layer')

      # find('input#role_new_person_privacy_policy_accepted').click

      expect do
        find_all('.btn-toolbar.bottom .btn-group button[type="submit"]').first.click # submit
      end.to_not change { Person.count }

      is_expected.to have_text('Um die Registrierung abzuschliessen, muss der Datenschutzerklärung zugestimmt werden.')
    end
  end


end
