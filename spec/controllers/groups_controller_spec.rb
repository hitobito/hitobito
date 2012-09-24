require 'spec_helper'

describe GroupsController do
  render_views

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader)  }

  #it_should_behave_like 'crud controller'
  #include_examples 'crud controller', skip: [%w()]
  
  describe "authentication" do
    it "redirects to login" do
      get :show, id: group.id 
      should redirect_to "/users/sign_in"
    end

    it "renders template when signed in" do
      sign_in(person)
      get :show, id: group.id
      should render_template('groups/show')
    end
  end


  describe "show, new then create" do
    before { sign_in(person) } 
    let(:group) { groups(:top_layer) }
    let(:attrs) {  { type: 'Group::TopGroup', parent_id: group.id } } 

    it "new" do
      get :new, group: attrs
      response.status.should == 200
      assigns(:group).type.should eq 'Group::TopGroup'
      assigns(:group).model.class.should eq Group::TopGroup
      assigns(:group).parent_id.should eq group.id
    end

    it "create" do
      post :create, group: attrs.merge(name: 'foobar')
      group = assigns(:group)
      should redirect_to group_path(group)
    end

    it "edit form" do
      get :edit, id: groups(:top_group)
      assigns(:contacts).should be_present
    end
  end

  describe "#destroy" do
    let(:top_group) { groups(:top_group) }
    let(:bottom_layer) { groups(:bottom_layer_one) }
    let(:top_group_leader) { Fabricate(Group::TopGroup::Leader.name.to_s, group: group ).person } 
    let(:top_group_member) { Fabricate(Group::TopGroup::Member.name.to_s, group: group ).person } 


    it "member cannot destroy group" do
      sign_in(top_group_member) 
      expect { post :destroy, id: top_group.id }.not_to change { Group.count }
    end

    it "leader can destroy group" do
      sign_in(top_group_leader) 
      expect { post :destroy, id: top_group.id }.to change(Group,:count).by(-1)
    end

    it "destroy also destroys all children" do
      sign_in(top_group_leader) 
      bottom_layer.children.size.should eq 2
      expect { post :destroy, id: bottom_layer.id }.to change(Group,:count).by(-3)
    end
  end
end
