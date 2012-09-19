require 'spec_helper'

describe RolesController do
  
  before { sign_in(people(:top_leader)) }
  
  let(:group)  { groups(:top_group) }
  let(:person) { Fabricate(:person)}
  
  it "redirects to people after create" do
    post :create, group_id: group.id, role: {group_id: group.id, person_id: person.id, type: Group::TopGroup::Member.sti_name}
    
    should redirect_to(group_people_path(group))
    
    role = person.reload.roles.first
    role.group_id.should == group.id
    role.should be_kind_of(Group::TopGroup::Member)
  end
  
  it "redirects to person after update" do
    role = Fabricate(Group::TopGroup::Member.name.to_sym, person: person, group: group)
    put :update, {group_id: group.id, id: role.id, role: {label: 'bla'}}
    
    should redirect_to(group_person_path(group, person))
    role.reload.label.should == 'bla'
  end
  
end
