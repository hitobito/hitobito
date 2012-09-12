require 'spec_helper'

describe GroupsController do

  let(:group) { Group.first }
  let(:person) { Person.first }
  
    #it_should_behave_like 'crud controller'
  #include_examples 'crud controller', skip: [%w()]
  
  let(:test_entry) { groups(:top_group) } 
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
