# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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

  describe 'with valid OAuth token' do
    let(:group) { groups(:top_layer) }
    let(:token) { instance_double('Doorkeeper::AccessToken', :acceptable? => true, :accessible? => true, :resource_owner_id => people(:top_leader).id) }

    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it 'GET index shows page' do
      get :show, params: { id: group.id }
      is_expected.to render_template('show')
    end
  end

  describe 'with invalid OAuth token (expired or revoked)' do
    let(:group) { groups(:top_layer) }
    let(:token) { instance_double('Doorkeeper::AccessToken', :acceptable? => true, :accessible? => false, :resource_owner_id => people(:top_leader).id) }

    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it 'GET index redirect to login' do
      get :show, params: { id: group.id }
      is_expected.to redirect_to('http://test.host/users/sign_in')
    end
  end

  describe 'without acceptable OAuth token (missing scope)' do
    let(:group) { groups(:top_layer) }
    let(:token) { instance_double('Doorkeeper::AccessToken', :acceptable? => false, :accessible? => true, :resource_owner_id => people(:top_leader).id) }

    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it 'GET index fails with HTTP 403 (forbidden)' do
      get :show, params: { id: group.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
