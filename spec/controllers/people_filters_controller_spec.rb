# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleFiltersController do

  before { sign_in(people(:top_leader)) }

  let(:group) { groups(:top_group) }
  let(:role_types) { [Group::TopGroup::Leader, Group::TopGroup::Member] }
  let(:role_type_ids) { role_types.collect(&:id) }
  let(:role_type_ids_string) { role_type_ids.join(RelatedRoleType::Assigners::ID_URL_SEPARATOR) }
  let(:role_type_names) { role_types.collect(&:sti_name) }

  context 'GET new' do
    it 'builds entry with group and existing params' do
      get :new, group_id: group.id, people_filter: { role_type_ids: role_type_ids_string }

      filter = assigns(:people_filter)
      filter.group.should == group
      filter.role_type_ids.should == role_type_ids
      filter.role_types.should == role_type_names
    end
  end

  context 'POST create' do
    it 'redirects to show for search' do
      expect do
        post :create, group_id: group.id, people_filter: { role_type_ids: role_type_ids }, button: 'search'
      end.not_to change { PeopleFilter.count }

      should redirect_to(group_people_path(group, role_type_ids: role_type_ids_string, kind: 'deep'))
    end

    it 'redirects to show for empty search' do
      expect do
        post :create, group_id: group.id, button: 'search'
      end.not_to change { PeopleFilter.count }

      should redirect_to(group_people_path(group))
    end

    it 'saves filter and redirects to show with save' do
      expect do
        expect do
          post :create, group_id: group.id, people_filter: { role_type_ids: role_type_ids, name: 'Test Filter' }, button: 'save'
          should redirect_to(group_people_path(group, role_type_ids: role_type_ids_string, kind: 'deep', name: 'Test Filter'))
        end.to change { PeopleFilter.count }.by(1)
      end.to change { RelatedRoleType.count }.by(2)
    end

    context 'with read only permissions' do
      before do
        @role = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
        @person = @role.person
        sign_in(@person)
      end

      let(:group) { @role.group }

      it 'redirects to show with search' do
        expect do
          post :create, group_id: group.id, people_filter: { role_type_ids: role_type_ids }, button: 'search'
        end.not_to change { PeopleFilter.count }

        should redirect_to(group_people_path(group, role_type_ids: role_type_ids_string, kind: 'deep'))
      end

      it 'is not authorized with save' do
        expect do
          post :create, group_id: group.id, people_filter: { role_type_ids: role_type_ids, name: 'Test Filter' }, button: 'save'
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

end
