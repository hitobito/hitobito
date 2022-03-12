# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe GroupsController do

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader)  }

  describe 'authentication' do
    it 'redirects to login' do
      get :show, params: { id: group.id }
      is_expected.to redirect_to '/users/sign_in'
    end

    it 'renders template when signed in' do
      sign_in(person)
      get :show, params: { id: group.id }
      is_expected.to render_template('crud/show')
    end
  end

  describe 'authenticated' do
    before { sign_in(person) }
    let(:group) { groups(:top_layer) }

    describe 'GET index' do
      context 'html' do
        it 'keeps flash' do
          get :index
          is_expected.to redirect_to(group_path(Group.root, format: :html))
        end
      end

      context 'json' do
        it 'redirects to json' do
          get :index, format: :json
          is_expected.to redirect_to(group_path(Group.root, format: :json))
        end
      end
    end

    describe 'GET show' do
      subject { assigns(:sub_groups) }

      context 'sub_groups' do
        before { get :show, params: { id: group.id } }

        its(:keys) { should == ['Bottom Layer', 'Untergruppen'] }
        its(:values) do
          should == [[groups(:bottom_layer_one), groups(:bottom_layer_two)],
                     [groups(:top_group), groups(:toppers)]]
        end
      end

      context 'deleted sub groups are not shown' do
        before do
          groups(:bottom_group_one_two).destroy
          get :show, params: { id: groups(:bottom_layer_one).id }
        end

        its(:values) { should == [[groups(:bottom_group_one_one)]] }
      end

      context 'json' do
        render_views

        it 'is valid' do
          get :show, params: { id: group.id }, format: :json
          json = JSON.parse(response.body)
          group = json['groups'].first
          expect(group['links']['children'].size).to eq(4)
        end
      end

    end

    describe 'show, new then create' do
      let(:attrs) {  { type: 'Group::TopGroup', parent_id: group.id } }

      it 'new' do
        get :new, params: { group: attrs }
        expect(response.status).to eq(200)
        expect(assigns(:group).type).to eq 'Group::TopGroup'
        expect(assigns(:group).model.class).to eq Group::TopGroup
        expect(assigns(:group).parent_id).to eq group.id
      end

      it 'create' do
        post :create, params: { group: attrs.merge(name: 'foobar') }
        group = assigns(:group)
        is_expected.to redirect_to group_path(group)
      end

      it 'edit form' do
        get :edit, params: { id: groups(:top_group) }
        expect(assigns(:contacts)).to be_present
      end

      it 'validates permission to read contact person' do
        invisible_person = Fabricate(:person)
        person = people(:bottom_member)
        group = groups(:bottom_layer_one)
        Fabricate(:role, type: 'Group::BottomLayer::Leader', person: person, group: group)
        sign_in(person)
        post :create, params: { group: { type: 'Group::BottomGroup', parent_id: group.id, contact_id: invisible_person.id, name: 'foobar' } }

        Auth.current_person = person
        group = assigns(:group)
        expect(group).not_to be_valid
        expect(group.errors.messages[:contact]).to include('Zugriff verweigert')
        Auth.current_person = nil
      end
    end

    describe 'PUT update' do
      let(:attrs) {  { type: 'Group::TopGroup', parent_id: group.id } }
      let(:top_leader_role) { roles(:top_leader) }
      let(:person) { top_leader_role.person }
      let(:group) { top_leader_role.group }

      before do
        group.update_columns(contact_id: 1)
      end

      it 'allows nil contact' do
        expect do
          put :update, params: { id: group, group: attrs.merge(name: 'foobar', contact_id: nil) }
        end.to change { group.reload.contact_id }.to(nil)
      end

      it 'allows member contact' do
        expect do
          put :update, params: { id: group, group: attrs.merge(name: 'foobar', contact_id: person.id ) }
        end.to change { group.reload.contact_id }.to(person.id)
      end

      it 'does not allow non-member contact' do
        non_member = people(:bottom_member)
        expect do
          put :update, params: { id: group, group: attrs.merge(name: 'foobar', contact_id: non_member.id) }
        end.not_to change { group.reload.contact_id }
      end
    end

    describe '#destroy' do
      it 'leader cannot destroy his group' do
        expect { post :destroy, params: { id: group.id } }.to raise_error(CanCan::AccessDenied)
      end

      it 'leader can destroy group' do
        expect { post :destroy, params: { id: groups(:bottom_group_one_two).id } }.to change { Group.without_deleted.count }.by(-1)
        is_expected.to redirect_to groups(:bottom_layer_one)
      end
    end

    describe '#deleted_subgroups' do
      let(:group) { groups(:bottom_group_one_one) }
      before { groups(:bottom_group_one_one_one).destroy }

      it 'assigns deleted_subgroups' do
        get :deleted_subgroups, params: { id: group.id }
        expect(assigns(:sub_groups).size).to eq(1)
      end
    end

    describe '#reactivate' do
      let(:group) { groups(:bottom_group_one_one_one) }

      before { group.destroy }

      it 'reactivates group and redirects' do
        expect(group).to be_deleted
        post :reactivate, params: { id: group.id }

        expect(Group.find(group.id)).to be_present
        expect(flash[:notice]).to eq 'Gruppe <i>Group 111</i> wurde erfolgreich reaktiviert.'
        is_expected.to redirect_to group
      end
    end

    describe '#export_subgroups' do
      let(:group) { groups(:top_layer) }

      it 'creates csv' do
        expect do
          get :export_subgroups, params: { id: group.id }
          expect(flash[:notice])
            .to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
        end.to change(Delayed::Job, :count).by(1)
      end
    end

  end

  describe 'token authenticated' do
    let(:group) { groups(:top_layer) }

    describe 'GET index' do
      it 'shows page when token is valid' do
        get :show, params: { id: group.id, token: 'PermittedToken' }
        is_expected.to render_template('show')
      end

      it 'does not show page for unpermitted token' do
        expect do
          get :show, params: { id: group.id, token: 'RejectedToken' }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'with valid oauth token' do
    let(:group) { groups(:top_layer) }
    let(:token) { Fabricate(:access_token, resource_owner_id: people(:top_leader).id) }

    before do
      allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { token }
      allow(token).to receive(:acceptable?) { true }
      allow(token).to receive(:accessible?) { true }
    end

    it 'GET index shows page' do
      get :show, params: { id: group.id }
      is_expected.to render_template('show')
    end
  end

  describe 'with invalid oauth token (expired or revoked)' do
    let(:group) { groups(:top_layer) }
    let(:token) { Fabricate(:access_token, resource_owner_id: people(:top_leader).id) }

    before do
      allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { token }
      allow(token).to receive(:acceptable?) { true }
      allow(token).to receive(:accessible?) { false }
    end

    it 'GET index redirect to login' do
      get :show, params: { id: group.id }
      is_expected.to redirect_to('http://test.host/users/sign_in')
    end
  end

  describe 'without acceptable oauth token (missing scope)' do
    let(:group) { groups(:top_layer) }
    let(:token) { Fabricate(:access_token, resource_owner_id: people(:top_leader).id) }

    before do
      allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { token }
      allow(token).to receive(:acceptable?) { false }
      allow(token).to receive(:accessible?) { true }
    end

    it 'GET index fails with HTTP 403 (forbidden)' do
      get :show, params: { id: group.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
