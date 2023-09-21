require 'spec_helper'

describe :self_inscription do

  subject { page }

  let(:group) { groups(:bottom_layer_one) }
  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }

  let(:password) { 's€cr€t-pa$$w0rd' }
  let(:user) { people(:bottom_member) }

  before do
    user.update!(password: password, password_confirmation: password)
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)

    expect(user.reload.roles.where(group_id: group.id, type: self_registration_role.name)).not_to exist
  end

  it 'with logged-in user gives user new role' do
    sign_in(user)
    visit group_self_inscription_path(group_id: group)

    expect(page).to have_selector('h1', text: 'Registrierung zu Bottom One')
    click_link('Einschreiben')

    expect(page).to have_content('Die Rolle wurde erfolgreich gespeichert')
    expect(user.reload.roles.where(group_id: group.id, type: self_registration_role.name)).to exist
  end

  it 'gives user new role after login' do
    logout
    visit group_self_inscription_path(group_id: group)

    expect(page).to have_selector('h1', text: 'Anmelden')
    fill_in 'Haupt-E-Mail', with: user.email
    fill_in 'Passwort', with: password
    click_button 'Anmelden'

    expect(page).to have_selector('h1', text: 'Registrierung zu Bottom One')
    click_link('Einschreiben')

    expect(page).to have_content('Die Rolle wurde erfolgreich gespeichert')
    expect(user.reload.roles.where(group_id: group.id, type: self_registration_role.name)).to exist
  end

end
