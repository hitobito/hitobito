require 'spec_helper'
describe GroupsController do

  let(:group) { Group.first }
  let(:person) { Person.first }
  
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
