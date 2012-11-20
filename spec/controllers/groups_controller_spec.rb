require 'spec_helper'

describe GroupsController do

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader)  }

  describe "authentication" do
    it "redirects to login" do
      get :show, id: group.id 
      should redirect_to "/users/sign_in"
    end

    it "renders template when signed in" do
      sign_in(person)
      get :show, id: group.id
      should render_template('crud/show')
    end
  end
  
  describe "show" do
    let(:group) { groups(:top_layer) }
    
    before do
      sign_in(person)
      get :show, id: group.id
    end
    
    context "sub_groups" do
      subject { assigns(:sub_groups) }
      
      its(:keys) { should == %w(Gruppen Untergruppen)}
      its(:values) { should == [[groups(:bottom_layer_one), groups(:bottom_layer_two)],
                                [groups(:top_group)]]}
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
    before { sign_in(person) }

    it "leader cannot destroy his group" do
      expect { post :destroy, id: group.id }.not_to change { Group.count }
    end

    it "leader can destroy group" do
      expect { post :destroy, id: groups(:bottom_layer_one).id }.to change(Group,:count).by(-4)
      should redirect_to groups(:top_layer)
    end
  end
end
