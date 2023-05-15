# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::SecurityToolsController do

  let(:nesting)    { { group_id: @user.primary_group.id, id: @user.id } }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'GET#index' do
    context 'html' do
      it 'can show security overview if able to edit person' do
        sign_in(top_leader)

        @user = bottom_member

        get :index, params: nesting

        expect(response).to have_http_status(200)
      end

      it 'can not show security overview if not able to edit person' do
        sign_in(bottom_member)

        @user = top_leader

        expect do
          get :index, params: nesting
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'js' do
      it 'loads roles that see me' do
        sign_in(bottom_member)

        @user = bottom_member

        get :index, params: nesting, xhr: true, format: :js

        expected_groups_and_roles = {}
        bottom_layer = groups(:bottom_layer_one)
        top_group = groups(:top_group)
        expected_groups_and_roles[bottom_layer.id] = { name: bottom_layer.name,
                                                       roles: [Group::BottomLayer::Leader.label,
                                                               Group::BottomLayer::LocalGuide.label,
                                                               Group::BottomLayer::Member.label] }
        expected_groups_and_roles[top_group.id] = { name: top_group.name,
                                                    roles: [Group::TopGroup::Leader.label,
                                                            Group::TopGroup::Secretary.label] }

        expect(assigns(:groups_and_roles_that_see_me)).to eq(expected_groups_and_roles)
      end
    end
  end
end
