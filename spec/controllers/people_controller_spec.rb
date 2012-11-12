require 'spec_helper'

describe PeopleController do
  
  before { sign_in(people(:top_leader)) }
  
  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  
  it "queries all people" do
    Fabricate(:person, first_name: 'Pascal')
    Fabricate(:person, last_name: 'Opassum')
    Fabricate(:person, last_name: 'Anything')
    get :query, q: 'pas'
    
    response.body.should =~ /Pascal/
    response.body.should =~ /Opassum/
  end
  
  it "creates new person with role" do
    post :create, group_id: group.id, 
                  role: {type: 'Group::TopGroup::Member', group_id: group.id},
                  person: {last_name: 'Foo', email: 'foo@example.com'}
                  
    person = assigns(:person)
    should redirect_to(group_person_path(group, person))
    person.should be_persisted
    person.roles.should have(1).item
    person.roles.first.should be_persisted
    last_email.should_not be_present
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

  describe "GET #show" do
    let(:gl) { qualification_kinds(:gl) }
    let(:sl) { qualification_kinds(:sl) }
    before do
      @ql_gl = Fabricate(:qualification, person: top_leader, qualification_kind: gl, finish_at: 1.year.from_now)
      @ql_sl = Fabricate(:qualification, person: top_leader, qualification_kind: sl, finish_at: Time.zone.now)
    end

    it "preloads data for asides, ordered by finish_at" do
      get :show, group_id: group.id, id: people(:top_leader).id
      assigns(:qualifications).should eq [@ql_sl, @ql_gl]
    end
  end

  describe "POST #send_password_instructions" do 
    let(:person) { people(:bottom_member) } 

    it "does not send instructions for self" do
      post :send_password_instructions, group_id: group.id, id: top_leader.id, format: :js
      flash[:notice].should_not be_present
      last_email.should_not be_present
    end

    it "sends password instructions" do
      post :send_password_instructions, group_id: groups(:bottom_layer_one).id, id: person.id, format: :js
      flash[:notice].should eq  'Login Informationen wurden verschickt.'
      last_email.should be_present
    end
  end
end
