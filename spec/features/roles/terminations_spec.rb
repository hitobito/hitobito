# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe :roles_terminations, js: true do
  let(:role) { roles(:bottom_member) }
  let(:person) { role.person }

  before do
    # make the role terminatable for the test
    Group::BottomLayer::Member.terminatable = true

    sign_in(person)
  end

  after do
    Group::BottomLayer::Member.terminatable = false
  end

  def visit_dialog
    visit history_group_person_path(group_id: role.group_id, id: person.id)
    click_link(href: /#{new_group_role_termination_path(group_id: role.group_id, role_id: role.id)}/)

    # wait for modal to appear before we continue
    expect(page).to have_selector('#role-termination.modal')
  end

  def submit_with_terminate_on(date) # rubocop:disable Metrics/AbcSize
    visit_dialog

    # it seems we have to clear the field before filling it directly instead of using the picker
    fill_in('Austrittsdatum', with: '')
    fill_in('Austrittsdatum', with: date.to_date.strftime('%d.%m.%Y'))

    click_button 'Austreten'
  end

  it 'lists all affected roles' do
    allow_any_instance_of(Roles::Termination).
      to receive(:affected_roles).and_return([roles(:top_leader), roles(:bottom_member)])

    visit_dialog

    within('.modal-dialog') do
      expect(page).to have_content "Top / TopGroup / Leader"
      expect(page).to have_content "Bottom One / Member"
    end
  end

  it 'mentions the role person' do
    visit_dialog

    within('.modal-dialog') do
      expect(page).to have_content /Austritt erfolgt für.*#{role.person.full_name}/
    end
  end

  it 'mentions the affected people' do
    allow_any_instance_of(Roles::Termination).
      to receive(:affected_people).and_return([people(:top_leader), people(:bottom_member)])

    visit_dialog

    within('.modal-dialog') do
      expect(page).to have_content /sowie für.*#{people(:top_leader).full_name}/
      expect(page).to have_content /sowie für.*#{people(:bottom_member).full_name}/
    end
  end

  it 'with valid date it terminates role' do
    terminate_on = Time.zone.tomorrow

    submit_with_terminate_on(terminate_on)

    expect(page).to have_current_path(group_person_path(group_id: role.group_id, id: person.id))
    within('#flash') do
      formatted_date = I18n.l(terminate_on)
      expect(page).to have_content("Du bist erfolgreich ausgetreten per #{formatted_date}")
    end

    expect { role.reload }.
      to change { role.delete_on }.to(terminate_on).
      and change { role.terminated }.to(true)
  end

  it 'with past date it shows error message' do
    submit_with_terminate_on(1.day.ago)

    # the modal dialog is still visible
    within('#role-termination.modal') do
      expect(page).to have_selector(
        '.errors .alert-danger',
        text: 'Austrittsdatum muss in der Zukunft liegen'
      )
    end
  end

  it 'with far future date it shows error message' do
    submit_with_terminate_on(2.years.from_now)

    # the modal dialog is still visible
    within('#role-termination.modal') do
      formatted_max_date = I18n.l(1.year.from_now.end_of_year.to_date)
      expect(page).to have_selector(
        '.errors .alert-danger',
        text: "Austrittsdatum darf nicht nach dem #{formatted_max_date} sein"
      )
    end
  end

  it 'for role with delete_on set has no input field' do
    delete_on = Time.zone.tomorrow
    role.update!(delete_on: delete_on)
    visit_dialog

    expect(page).not_to have_field('Austrittsdatum')
    expect(page).to have_content("Austrittsdatum: #{delete_on.strftime('%d.%m.%Y')}")
  end
end
