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
      get :show, id: group.id
      should redirect_to '/users/sign_in'
    end

    it 'renders template when signed in' do
      sign_in(person)
      get :show, id: group.id
      should render_template('crud/show')
    end
  end

  describe 'authenticated' do
    before { sign_in(person) }
    let(:group) { groups(:top_layer) }

    describe 'GET index' do
      context :html do
        it 'keeps flash' do
          get :index
          should redirect_to(group_path(Group.root, format: :html))
        end
      end

      context :json do
        it 'redirects to json' do
          get :index, format: :json
          should redirect_to(group_path(Group.root, format: :json))
        end
      end
    end

    describe 'GET show' do
      subject { assigns(:sub_groups) }

      context 'sub_groups' do
        before { get :show, id: group.id }

        its(:keys) { should == ['Bottom Layer', 'Untergruppen'] }
        its(:values) do
          should == [[groups(:bottom_layer_one), groups(:bottom_layer_two)],
                     [groups(:top_group), groups(:toppers)]]
        end
      end

      context 'deleted sub groups are not shown' do
        before do
          groups(:bottom_group_one_two).destroy
          get :show, id: groups(:bottom_layer_one).id
        end

        its(:values) { should == [[groups(:bottom_group_one_one)]] }
      end

      context :json do
        render_views

        it 'is valid' do
          get :show, id: group.id, format: :json
          json = JSON.parse(response.body)
          group = json['groups'].first
          group['links']['children'].should have(4).items
        end
      end

    end

    describe 'show, new then create' do
      let(:attrs) {  { type: 'Group::TopGroup', parent_id: group.id } }

      it 'new' do
        get :new, group: attrs
        response.status.should == 200
        assigns(:group).type.should eq 'Group::TopGroup'
        assigns(:group).model.class.should eq Group::TopGroup
        assigns(:group).parent_id.should eq group.id
      end

      it 'create' do
        post :create, group: attrs.merge(name: 'foobar')
        group = assigns(:group)
        should redirect_to group_path(group)
      end

      it 'edit form' do
        get :edit, id: groups(:top_group)
        assigns(:contacts).should be_present
      end
    end

    describe '#destroy' do
      it 'leader cannot destroy his group' do
        expect { post :destroy, id: group.id }.to raise_error(CanCan::AccessDenied)
      end

      it 'leader can destroy group' do
        expect { post :destroy, id: groups(:bottom_group_one_two).id }.to change { Group.without_deleted.count }.by(-1)
        should redirect_to groups(:bottom_layer_one)
      end
    end

    describe '#deleted_subgroups' do
      let(:group) { groups(:bottom_group_one_one) }
      before { groups(:bottom_group_one_one_one).destroy }

      it 'assigns deleted_subgroups' do
        get :deleted_subgroups, id: group.id
        assigns(:sub_groups).should have(1).item
      end
    end

    describe '#reactivate' do
      let(:group) { groups(:bottom_group_one_one_one) }

      before { group.destroy }

      it 'reactivates group and redirects' do
        group.should be_deleted
        post :reactivate, id: group.id

        Group.find(group.id).should be_present
        flash[:notice].should eq 'Gruppe <i>Group 111</i> wurde erfolgreich reaktiviert.'
        should redirect_to group
      end
    end

    describe '#export_subgroups' do
      let(:group) { groups(:top_layer) }

      it 'creates csv' do
        get :export_subgroups, id: group.id

        @response.content_type.should == 'text/csv'
        lines = @response.body.split("\n")
        lines.should have(10).items
        lines[0].should =~ /^Id;Elterngruppe;Name;.*/
        lines[1].should =~ /^#{group.id};;Top;.*/
        lines[2].should =~ /^#{groups(:bottom_layer_one).id};#{group.id};Bottom One;.*/
      end
    end
  end
end
