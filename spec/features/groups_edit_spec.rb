# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe :groups_edit, type: :feature do
  before { sign_in(people(:root)) }

  context 'self_registration tab and fields' do
    let(:self_reg_group) { groups(:bottom_group_one_one) }
    let(:non_self_reg_group) do
      # a group which has only read-write roles
      group_class = Class.new(Group) do
        self.layer = true
        self.role_types = [Group::TopGroup::Leader]
      end
      stub_const('NonSelfRegGroup', group_class)
      NonSelfRegGroup.create!(name: 'NonSelfRegGroup')
    end

    context 'with self_registration is enabled' do
      before do
        allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
      end

      it 'tab and fields are visible when group has compatible roles' do
        expect(self_reg_group.decorate.supports_self_registration?).to eq true

        visit edit_group_path(self_reg_group)
        expect(page).to have_link('Externe Registrierung')

        click_on('Externe Registrierung')
        expect(page).to have_field('Rollentyp')
      end

      it 'tab and fields are not visible when group has no compatible roles' do
        expect(non_self_reg_group.decorate.supports_self_registration?).to eq false

        visit edit_group_path(non_self_reg_group)

        expect(page).to have_link('Allgemein')
        expect(page).to have_no_link('Externe Registrierung')
        expect(page).to have_no_field('Rollentyp')
      end
    end

    context 'with self_registration is disabled' do
      before do
        allow(Settings.groups.self_registration).to receive(:enabled).and_return(false)
      end

      it 'tab and fields are not visible' do
        visit edit_group_path(self_reg_group)

        expect(page).to have_link('Allgemein')
        expect(page).to have_no_link('Externe Registrierung')
        expect(page).to have_no_field('Rollentyp')
      end
    end
  end
end
