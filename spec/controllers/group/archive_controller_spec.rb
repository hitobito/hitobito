# frozen_string_literal: true

#  Copyright (c) 2021, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::ArchiveController, type: :controller do

  describe 'POST #create' do
    let(:bottom_group) { groups(:bottom_group_one_two) }
    let(:group_id) { bottom_group.id }

    before do
      sign_in(people(:top_leader))
    end

    it 'returns http success' do
      post :create, params: { id: group_id }
      expect(response).to have_http_status(:redirect)
    end

    it 'finishes all roles' do
      Fabricate(Group::BottomGroup::Member.sti_name,
                person_id: people(:bottom_member).id,
                group_id: group_id)

      expect do
        post :create, params: { id: group_id }
      end.to change { Role.where(group_id: group_id, archived_at: nil).count }.by(-1)
    end

    it 'archives the group' do
      expect do
        post :create, params: { id: group_id }
      end.to change { bottom_group.reload.archived? }.from(false).to(true)
    end
  end

end
