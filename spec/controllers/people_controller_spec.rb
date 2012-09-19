require 'spec_helper'

describe PeopleController do
  
  before { sign_in(people(:top_leader)) }
  
  let(:group) { groups(:top_group) }
  
  it "creates new person with role" do
    post :create, group_id: group.id, 
                  role: {type: 'Group::TopGroup::Member', group_id: group.id},
                  person: {last_name: 'Foo', email: 'foo@example.com'}
                  
    person = assigns(:person)
    should redirect_to(group_person_path(group, person))
    person.should be_persisted
    person.roles.should have(1).item
    person.roles.first.should be_persisted
  end
  
  it "does not create person with not allowed role" do
    user = Fabricate(Group::BottomGroup::Leader.name.to_s, group: groups(:bottom_group_one_one))
    sign_in(user.person)
    
    expect {
      post :create, group_id: group.id, 
                    role: {type: 'Group::TopGroup::Member', group_id: group.id},
                    person: {last_name: 'Foo', email: 'foo@example.com'}
    }.not_to change { Person.count }
                  
    should redirect_to(root_path)
  end
end
