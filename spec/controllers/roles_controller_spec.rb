# encoding: UTF-8
require 'spec_helper'

describe RolesController do
  
  before { sign_in(people(:top_leader)) }
  
  let(:group)  { groups(:top_group) }
  let(:person) { Fabricate(:person)}
  let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, person: person, group: group) } 
    
  it "GET new sets a role of the correct type" do
    get :new, {group_id: group.id, role: {group_id: group.id, type: Group::TopGroup::Member.sti_name}}
    
    assigns(:role).should be_kind_of(Group::TopGroup::Member)
    assigns(:role).group_id.should == group.id
  end
  
  it "POST create redirects to people after create" do
    post :create, group_id: group.id, role: {group_id: group.id, person_id: person.id, type: Group::TopGroup::Member.sti_name}
    
    should redirect_to(group_people_path(group))
    
    role = person.reload.roles.first
    role.group_id.should == group.id
    flash[:notice].should == "Rolle <i>Rolle</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich erstellt."
    role.should be_kind_of(Group::TopGroup::Member)
  end

  describe "PUT update" do
    let(:notice) { "Rolle <i>bla (Rolle)</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich aktualisiert."  } 
    

    it "redirects to person after update" do
      put :update, {group_id: group.id, id: role.id, role: {label: 'bla', type: role.type}}
      
      flash[:notice].should eq notice
      role.reload.label.should eq 'bla'
      should redirect_to(group_person_path(group, person))
    end

    it "can handle type passed as param" do
      put :update, {group_id: group.id, id: role.id, role: {label: 'foo', type: role.type}}
      role.reload.type.should eq Group::TopGroup::Member.model_name
      role.reload.label.should eq 'foo'
    end


    it "terminates and creates new role if type changes" do
      put :update, {group_id: group.id, id: role.id, role: {type: Group::TopGroup::Leader}}
      should redirect_to(group_person_path(group, person))
      Role.unscoped.where(id: role.id).should_not be_exists
      notice = "Rolle <i>Rolle</i> für <i>#{person}</i> in <i>TopGroup</i> zu <i>Rolle</i> geändert."
      flash[:notice].should eq notice
    end

  end

  describe "POST destroy" do
    let(:notice) { "Rolle <i>Rolle</i> für <i>#{person}</i> in <i>TopGroup</i> wurde erfolgreich gelöscht." } 

    
    it "redirects to group" do
      post :destroy, {group_id: group.id, id: role.id }

      flash[:notice].should eq notice
      should redirect_to(group_path(group))
    end

    it "redirects to person if user can still view person" do
      Fabricate(Group::TopGroup::Leader.name.to_sym, person: person, group: group)
      post :destroy, {group_id: group.id, id: role.id }

      flash[:notice].should eq notice
      should redirect_to(person_path(person))
    end

  end

end
