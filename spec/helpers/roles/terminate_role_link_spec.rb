# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Roles::TerminateRoleLink do
  context '#render' do
    it 'returns empty string if role is not terminatable' do
      role = roles(:top_leader)
      expect(role).to receive(:terminatable?).and_return(false)

      expect(described_class.new(role, view).render).to eq(nil)
    end

    it 'returns link if role is terminatable and user has permission' do
      role = roles(:top_leader)
      expect(role).to receive(:terminatable?).and_return(true)
      expect(view).to receive(:can?).with(:terminate, role).and_return(true)

      expect(described_class.new(role, view).render).
        to eq "<a class=\"btn btn-xs float-right\" data-remote=\"true\" href=\"/groups/#{role.group.id}/roles/#{role.id}/terminations/new\">Austritt</a>"
    end

    it 'returns disabled button if role is terminatable and user has no permission' do
      role = roles(:top_leader)
      expect(role).to receive(:terminatable?).and_return(true)
      expect(view).to receive(:can?).with(:terminate, role).and_return(false)

      expect(described_class.new(role, view).render).
        to eq '<div rel="tooltip" title=""><button name="button" type="submit" class="btn btn-xs float-right" disabled="disabled">Austritt</button></div>'
    end

    it 'returns disabled button with translated tooltip' do
      role = roles(:top_leader)
      expect(role).to receive(:terminatable?).and_return(true)
      expect(view).to receive(:can?).with(:terminate, role).and_return(false)

      with_translations(
        de: { 'roles/terminations': { global: {
          role: { no_permission: 'generic role no permission' },
          'group/top_group/leader': { no_permission: 'top group leader no permission' }
        } } }
      ) do
        expect(described_class.new(role, view).render).
          to match(/title="top group leader no permission"/)
      end
    end
  end
end
