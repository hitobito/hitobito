# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe RolesController do

  before { sign_in(people(:top_leader)) }

  let(:group)  { groups(:top_group) }
  let(:person) { Fabricate(:person) }
  let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, person: person, group: group) }

  it 'GET new sets a role of the correct type' do
    get :new, { group_id: group.id, role: { group_id: group.id, type: Group::TopGroup::Member.sti_name } }

    assigns(:role).should be_kind_of(Group::TopGroup::Member)
    assigns(:role).group_id.should == group.id
  end

  describe 'POST create' do
    it 'new role for existing person and redirects to people' do
      post :create, group_id: group.id, role: { group_id: group.id, person_id: person.id, type: Group::TopGroup::Member.sti_name }

      should redirect_to(group_people_path(group))

      role = person.reload.roles.first
      role.group_id.should == group.id
      flash[:notice].should == "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich erstellt."
      role.should be_kind_of(Group::TopGroup::Member)
    end

    it 'new role and new person and redirects to person' do
      post :create, group_id: group.id,
                    role: { group_id: group.id,
                            person_id: nil,
                            type: Group::TopGroup::Member.sti_name,
                            new_person: { first_name: 'Hans',
                                          last_name: 'Beispiel' } }

      role = assigns(:role)
      should redirect_to(group_person_path(group, role.person))

      role.group_id.should == group.id
      flash[:notice].should == "Rolle <i>Member</i> für <i>Hans Beispiel</i> in <i>TopGroup</i> wurde erfolgreich erstellt."
      role.should be_kind_of(Group::TopGroup::Member)
      person = role.person
      person.first_name.should == 'Hans'
    end

    it 'without name renders form again' do
      post :create, group_id: group.id,
                    role: { group_id: group.id,
                            person_id: nil,
                            type: Group::TopGroup::Member.sti_name,
                            new_person: { } }

      should render_template('new')

      role = assigns(:role)
      role.person.should have(1).error_on(:base)
    end

    it 'without type displays error' do
      post :create, group_id: group.id, role: { group_id: group.id, person_id: person.id }

      should render_template('new')
      assigns(:role).should have(1).error_on(:type)
    end

    it 'with invalid person_id displays error' do
      post :create, group_id: group.id, role: { group_id: group.id, type: Group::TopGroup::Member.sti_name, person_id: -99 }

      should render_template('new')
      assigns(:role).person.should have(1).error_on(:base)
    end

  end

  describe 'PUT update' do
    let(:notice) { "Rolle <i>bla (Member)</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich aktualisiert."  }


    it 'redirects to person after update' do
      put :update, { group_id: group.id, id: role.id, role: { label: 'bla', type: role.type } }

      flash[:notice].should eq notice
      role.reload.label.should eq 'bla'
      should redirect_to(group_person_path(group, person))
    end

    it 'can handle type passed as param' do
      put :update, { group_id: group.id, id: role.id, role: { label: 'foo', type: role.type } }
      role.reload.type.should eq Group::TopGroup::Member.model_name
      role.reload.label.should eq 'foo'
    end


    it 'terminates and creates new role if type changes' do
      put :update, { group_id: group.id, id: role.id, role: { type: Group::TopGroup::Leader } }
      should redirect_to(group_person_path(group, person))
      Role.with_deleted.where(id: role.id).should_not be_exists
      notice = "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> zu <i>Leader</i> geändert."
      flash[:notice].should eq notice
    end

  end

  describe 'POST destroy' do
    let(:notice) { "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich gelöscht." }


    it 'redirects to group' do
      post :destroy, { group_id: group.id, id: role.id }

      flash[:notice].should eq notice
      should redirect_to(group_path(group))
    end

    it 'redirects to person if user can still view person' do
      Fabricate(Group::TopGroup::Leader.name.to_sym, person: person, group: group)
      post :destroy, { group_id: group.id, id: role.id }

      flash[:notice].should eq notice
      should redirect_to(person_path(person))
    end
  end

  describe 'GET details' do
     it 'renders template' do
       get :details, format: :js, role: { type: Group::TopGroup::Member.sti_name }, group_id: group.id

       should render_template('details')
       assigns(:type).should == Group::TopGroup::Member
     end
  end

  describe 'handling return_url param' do
    it 'POST create redirects to people after create' do
      post :create, group_id: group.id,
                    role: { group_id: group.id, person_id: person.id, type: Group::TopGroup::Member.sti_name },
                    return_url: group_person_path(group, person)
      should redirect_to group_person_path(group, person)
    end
  end

end
