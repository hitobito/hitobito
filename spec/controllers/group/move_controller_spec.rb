# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Group::MoveController do

  render_views

  let(:user) { people(:top_leader) }
  let(:group) { groups(:bottom_group_one_one) }
  let(:target) { groups(:bottom_layer_two) }

  before { sign_in(user) }

  context 'GET :select' do
    it 'assigns candidates' do
      get :select, id: group.id
      expect(assigns(:candidates)['Bottom Layer']).to include target
    end
  end

  context 'POST :perform' do
    it 'performs moving' do
      post :perform, id: group.id, move: { target_group_id: target.id }
      expect(flash[:notice]).to eq "#{group} wurde nach #{target} verschoben."
      is_expected.to redirect_to(group)
    end
  end

end
