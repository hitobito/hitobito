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

  describe 'POST#block_person' do
    let(:person) { bottom_member }
    let(:nesting) { { group_id: person.primary_group.id, id: person.id } }
    subject(:block_person) { post :block_person, params: nesting }

    it 'sets the blocked_at attribute' do
      block_person
      expect(response).to redirect_to(security_tools_group_person_path(person.primary_group.id, person.id))
      expect(flash[:notice]).to eq(I18n.t('person.security_tools.block_person.flashes.success'))
      expect(person.reload).to be_blocked
    end

    context 'without permissions' do
      let(:person) { top_leader }
      it 'cannot block a person' do
        sign_in(bottom_member)
        expect { block_person }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'with herself' do
      let(:person) { top_leader }

      it 'cannot block herself' do
        block_person
        expect(response).to redirect_to(security_tools_group_person_path(person.primary_group.id, person.id))
        expect(flash[:alert]).to eq(I18n.t('person.security_tools.block_person.flashes.error'))
        expect(person.reload).not_to be_blocked
      end
    end

    context 'with impersonation' do
      let(:impersonator_role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
      let(:person) { impersonator_role.person }

      it 'cannot block impersonator' do
        allow(controller).to receive(:session).and_return(origin_user: impersonator_role.person.id)
        block_person
        expect(response).to redirect_to(security_tools_group_person_path(person.primary_group.id, person.id))
        expect(flash[:alert]).to eq(I18n.t('person.security_tools.block_person.flashes.error'))
        expect(person.blocked_at).to be_nil
      end
    end
  end

  describe 'POST#unblock_person' do
    let(:person) { bottom_member }
    let(:nesting) { { group_id: person.primary_group.id, id: person.id } }
    subject(:unblock_person) { post :unblock_person, params: nesting }

    it 'resets the blocked_at attribute' do
      person.update(blocked_at: 1.month.ago, inactivity_block_warning_sent_at: 2.months.ago)
      unblock_person
      expect(response).to redirect_to(security_tools_group_person_path(person.primary_group.id, person.id))
      expect(flash[:notice]).to eq(I18n.t('person.security_tools.unblock_person.flashes.success'))
      person.reload
      expect(person.blocked_at).to be_nil
      expect(person.inactivity_block_warning_sent_at).to be_nil
    end

    it 'logs a message with paper_trail' do
      expect { unblock_person }.to change { PaperTrail::Version.count }.by(1)
    end

    context 'without permissions' do
      let(:person) { top_leader }
      it 'cannot block a person' do
        sign_in(bottom_member)
        expect { unblock_person }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
