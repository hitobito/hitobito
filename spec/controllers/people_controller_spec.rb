require 'spec_helper'

describe PeopleController do
  
  before { sign_in(top_leader) }
  
  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  
  context "GET index" do
    
    before do
      @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
      @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person
      
      @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
      @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person
      
      @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
      @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
    end
    
    context "group" do
      it "loads all members of a group" do
        get :index, group_id: group
        
        assigns(:people).collect(&:id).should =~ [top_leader, @tg_member].collect(&:id)
      end
      
      it "loads externs of a group when type given" do
        get :index, group_id: group, role_types: [Role::External.sti_name]
        
        assigns(:people).collect(&:id).should =~ [@tg_extern].collect(&:id)
      end
      
      it "loads selected roles of a group when types given" do
        get :index, group_id: group, role_types: [Role::External.sti_name, Group::TopGroup::Member.sti_name]
        
        assigns(:people).collect(&:id).should =~ [@tg_member, @tg_extern].collect(&:id)
      end
      
      it "generates pdf labels" do
        get :index, group_id: group, label_format_id: label_formats(:standard).id, format: :pdf
        
        @response.content_type.should == 'application/pdf'
        people(:top_leader).reload.last_label_format.should == label_formats(:standard)
      end
    end
    
    context "layer" do
      let(:group) { groups(:bottom_layer_one) }
      
      before { sign_in(@bl_leader) }
      
      it "loads group members when no types given" do
        get :index, group_id: group, kind: 'layer'
        
        assigns(:people).collect(&:id).should =~ [people(:bottom_member), @bl_leader].collect(&:id)
      end
      
      it "loads selected roles of a group when types given" do
        get :index, group_id: group, 
                    role_types: [Group::BottomGroup::Member.sti_name, Role::External.sti_name], 
                    kind: 'layer'
        
        assigns(:people).collect(&:id).should =~ [@bg_member, @bl_extern].collect(&:id)
      end
    end
    
    context "deep" do
      let(:group) { groups(:top_layer) }
      
      it "loads group members when no types are given" do
        get :index, group_id: group, kind: 'deep'
        
        assigns(:people).collect(&:id).should =~ []
      end
      
      it "loads selected roles of a group when types given" do
        get :index, group_id: group, 
                    role_types: [Group::BottomGroup::Leader.sti_name, Role::External.sti_name], 
                    kind: 'deep'
        
        assigns(:people).collect(&:id).should =~ [@bg_leader, @tg_extern].collect(&:id)
      end
    end
  end
  
  context "GET query" do
    it "queries all people" do
      Fabricate(:person, first_name: 'Pascal')
      Fabricate(:person, last_name: 'Opassum')
      Fabricate(:person, last_name: 'Anything')
      get :query, q: 'pas'
      
      response.body.should =~ /Pascal/
      response.body.should =~ /Opassum/
    end
  end
  
  context "POST create" do
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
  
  describe "GET show" do
        
    it "generates pdf labels" do
      get :show, group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id, format: :pdf
      
      @response.content_type.should == 'application/pdf'
      people(:top_leader).reload.last_label_format.should == label_formats(:standard)
    end
    
  end
end
