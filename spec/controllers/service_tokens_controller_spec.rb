#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ServiceTokensController do
    let(:role)   { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }
    let(:person) { role.person }

    before { sign_in(person) }

    context 'authorization' do
      it 'may index when person has permission' do
        get :index, group_id: role.group
        expect(response).to be_success
      end

      it "may not index when person has no permission on top group" do
        expect do
          get :index, group_id: groups(:top_group).id
        end.to raise_error(CanCan::AccessDenied)
      end
    end

end
