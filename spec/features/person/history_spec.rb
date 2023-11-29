# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe :person_history, js: true do
  let(:role) { roles(:top_leader) }
  let(:person) { role.person }

  before { sign_in(person) }


  context 'termination links' do
    it 'is not visible for role with terminatable?=false' do
      allow_any_instance_of(Role).to receive(:terminatable?).and_return(false)

      visit history_group_person_path(group_id: role.group_id, id: person.id)

      expect(page).to have_no_link(nil,
                                   href: new_group_role_termination_path(role.group_id, role.id))
    end

    it 'is visible for role with terminatable?=true' do
      allow_any_instance_of(Role).to receive(:terminatable?).and_return(true)

      visit history_group_person_path(group_id: role.group_id, id: person.id)

      expect(page).to have_link('Austritt',
                                href: new_group_role_termination_path(role.group_id, role.id))
    end
  end
end
