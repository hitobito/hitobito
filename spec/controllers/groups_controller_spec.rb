require 'spec_helper'

describe GroupsController do
  render_views

  let(:group) { Group.first }
  let(:person) { Person.first }
  let(:test_entry) { groups(:top_group) } 

  #it_should_behave_like 'crud controller'
  #include_examples 'crud controller', skip: [%w()]
  
  describe "authentication" do
    let(:test_entry_attrs) do
      {:name => 'foo',
       :short_name => 'f',
       :parent_id => groups(:top_layer).id}
    end
    
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
      ability = Ability::WithGroup.new(person, group)
      Ability::WithGroup.should_receive(:new).with(person, group) { ability }
      get :new, group: attrs
      assigns(:group).type.should eq 'Group::TopGroup'
      assigns(:group).class.should eq Group::TopGroup
      assigns(:group).parent_id.should eq group.id
      assigns(:current_ability).should eq ability
    end

    it "create" do
      post :create, group: attrs.merge(name: 'foobar')
      group = assigns(:group)
      should redirect_to "/groups/#{group.id}"
    end

    it "edit form" do
      get :edit, id: groups(:top_group)
      assigns(:contacts).should be_present
    end
  end

end
