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
    get :new,  group_id: group.id, role: { group_id: group.id, type: Group::TopGroup::Member.sti_name }

    expect(assigns(:role)).to be_kind_of(Group::TopGroup::Member)
    expect(assigns(:role).group_id).to eq(group.id)
  end

  describe 'POST create' do
    it 'new role for existing person redirects to people list' do
      post :create, group_id: group.id,
                    role: { group_id: group.id,
                            person_id: person.id,
                            type: Group::TopGroup::Member.sti_name }

      is_expected.to redirect_to(group_people_path(group))

      role = person.reload.roles.first
      expect(role.group_id).to eq(group.id)
      expect(flash[:notice]).to eq("Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich erstellt.")
      expect(role).to be_kind_of(Group::TopGroup::Member)
    end

    it 'new role for new person redirects to person show' do
      post :create, group_id: group.id,
                    role: { group_id: group.id,
                            person_id: nil,
                            type: Group::TopGroup::Member.sti_name,
                            new_person: { first_name: 'Hans',
                                          last_name: 'Beispiel' } }

      role = assigns(:role)
      is_expected.to redirect_to(group_person_path(group, role.person))

      expect(role.group_id).to eq(group.id)
      expect(flash[:notice]).to eq('Rolle <i>Member</i> für <i>Hans Beispiel</i> in <i>TopGroup</i> wurde erfolgreich erstellt.')
      expect(role).to be_kind_of(Group::TopGroup::Member)
      person = role.person
      expect(person.first_name).to eq('Hans')
    end

    it 'new role for different group redirects to groups peope list' do
      g = groups(:toppers)
      post :create, group_id: group.id,
                    role: { group_id: g.id,
                            person_id: person.id,
                            type: Group::GlobalGroup::Member.sti_name }

      is_expected.to redirect_to(group_people_path(g))

      role = person.reload.roles.first
      expect(role.group_id).to eq(g.id)
      expect(flash[:notice]).to eq("Rolle <i>Member</i> für <i>#{person}</i> in <i>Toppers</i> wurde erfolgreich erstellt.")
      expect(role).to be_kind_of(Group::GlobalGroup::Member)
    end

    it 'without name renders form again' do
      post :create, group_id: group.id,
                    role: { group_id: group.id,
                            person_id: nil,
                            type: Group::TopGroup::Member.sti_name,
                            new_person: {} }

      is_expected.to render_template('new')

      role = assigns(:role)
      expect(role.person).to have(1).error_on(:base)
    end

    it 'without type displays error' do
      post :create, group_id: group.id, role: { group_id: group.id, person_id: person.id }

      is_expected.to render_template('new')
      expect(assigns(:role)).to have(1).error_on(:type)
    end

    it 'with invalid person_id displays error' do
      post :create, group_id: group.id, role: { group_id: group.id, type: Group::TopGroup::Member.sti_name, person_id: -99 }

      is_expected.to render_template('new')
      expect(assigns(:role).person).to have(1).error_on(:base)
    end

    context 'as group_full' do
      before { sign_in(Fabricate(Group::TopGroup::Secretary.name.to_sym, group: group).person) }

      it 'new role for existing person redirects to people list' do
        post :create, group_id: group.id,
                      role: { group_id: group.id,
                              person_id: person.id,
                              type: Group::TopGroup::Member.sti_name }

        is_expected.to redirect_to(group_people_path(group))

        role = person.reload.roles.first
        expect(role.group_id).to eq(group.id)
        expect(flash[:notice]).to eq("Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich erstellt.")
        expect(role).to be_kind_of(Group::TopGroup::Member)
      end

      it 'new role for different group is not allowed' do
        g = groups(:toppers)
        expect do
          post :create, group_id: group.id,
                        role: { group_id: g.id,
                                person_id: person.id,
                                type: Group::GlobalGroup::Member.sti_name }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

  end

  describe 'PUT update' do

    before { role } # create it

    it 'without type displays error' do
      put :update, group_id: group.id, id: role.id, role: { group_id: group.id, person_id: person.id, type: "" }

      expect(assigns(:role)).to have(1).error_on(:type)
      is_expected.to render_template('edit')
    end

    it 'redirects to person after update' do
      expect do
        put :update,  group_id: group.id, id: role.id, role: { label: 'bla', type: role.type, group_id: role.group_id }
      end.not_to change { Role.with_deleted.count }

      expect(flash[:notice]).to eq "Rolle <i>Member (bla)</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich aktualisiert."
      expect(role.reload.label).to eq 'bla'
      expect(role.type).to eq Group::TopGroup::Member.model_name
      is_expected.to redirect_to(group_person_path(group, person))
    end

    it 'terminates and creates new role if type changes' do
      expect do
        put :update, group_id: group.id, id: role.id, role: { type: Group::TopGroup::Leader.sti_name }
      end.not_to change { Role.with_deleted.count }
      is_expected.to redirect_to(group_person_path(group, person))
      expect(Role.with_deleted.where(id: role.id)).not_to be_exists
      expect(flash[:notice]).to eq "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> zu <i>Leader</i> geändert."
    end

    it 'terminates and creates new role if type and group changes' do
      g = groups(:toppers)
      expect do
        put :update, group_id: group.id, id: role.id, role: { type: Group::GlobalGroup::Leader.sti_name, group_id: g.id }
      end.not_to change { Role.with_deleted.count }
      is_expected.to redirect_to(group_person_path(g, person))
      expect(Role.with_deleted.where(id: role.id)).not_to be_exists
      expect(flash[:notice]).to eq "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> zu <i>Leader</i> in <i>Toppers</i> geändert."
    end

    context 'multiple groups' do
      let(:group) { groups(:bottom_group_one_one) }
      let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: group) }

      it 'terminates and creates new role if group changes' do
        g = groups(:bottom_group_one_two)
        expect do
          put :update, group_id: group.id, id: role.id, role: { type: Group::BottomGroup::Leader.sti_name, group_id: g.id }
        end.not_to change { Role.with_deleted.count }
        is_expected.to redirect_to(group_person_path(g, person))
        expect(Role.with_deleted.where(id: role.id)).not_to be_exists
        expect(flash[:notice]).to eq "Rolle <i>Leader</i> für <i>#{person}</i> in <i>Group 11</i> zu <i>Leader</i> in <i>Group 12</i> geändert."
      end
    end

    context 'as group_full' do
      before { sign_in(Fabricate(Group::TopGroup::Secretary.name.to_sym, group: group).person) }

      it 'terminates and creates new role if type changes' do
        expect do
          put :update,  group_id: group.id, id: role.id, role: { type: Group::TopGroup::Leader.sti_name }
        end.not_to change { Role.with_deleted.count }
        is_expected.to redirect_to(group_person_path(group, person))
        expect(Role.with_deleted.where(id: role.id)).not_to be_exists
        expect(flash[:notice]).to eq "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> zu <i>Leader</i> geändert."
      end

      it 'is not allowed if group changes' do
        g = groups(:toppers)
        expect do
          put :update,  group_id: group.id, id: role.id, role: { type: Group::GlobalGroup::Member.sti_name, group_id: g.id }
        end.to raise_error(CanCan::AccessDenied)
        expect(Role.with_deleted.where(id: role.id)).to be_exists
      end
    end
  end

  describe 'POST destroy' do
    let(:notice) { "Rolle <i>Member</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich gelöscht." }


    it 'redirects to group' do
      post :destroy,  group_id: group.id, id: role.id

      expect(flash[:notice]).to eq notice
      is_expected.to redirect_to(group_path(group))
    end

    it 'redirects to person if user can still view person' do
      Fabricate(Group::TopGroup::Leader.name.to_sym, person: person, group: group)
      post :destroy,  group_id: group.id, id: role.id

      expect(flash[:notice]).to eq notice
      is_expected.to redirect_to(person_path(person))
    end
  end

  describe 'GET details' do
     it 'renders template' do
       xhr :get,
          :details,
          format: :js,
          role: { type: Group::TopGroup::Member.sti_name },
          group_id: group.id

       is_expected.to render_template('details')
       expect(assigns(:type)).to eq(Group::TopGroup::Member)
     end
  end

  describe 'handling return_url param' do
    it 'POST create redirects to people after create' do
      post :create, group_id: group.id,
                    role: { group_id: group.id, person_id: person.id, type: Group::TopGroup::Member.sti_name },
                    return_url: group_person_path(group, person)
      is_expected.to redirect_to group_person_path(group, person)
    end
  end

end
