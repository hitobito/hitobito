require 'spec_helper'

describe PeopleController do
  
  let(:user) { people(:top_leader) }
  
  it "signs in with valid token" do
    user.generate_reset_password_token!
    get :show, group_id: user.groups.first.id, id: user.id, onetime_token: user.reset_password_token
    
    assigns(:current_person).should be_present
    should render_template('crud/show')
  end
  
  it "cannot sign in with expired token" do
    user.generate_reset_password_token!
    user.update_column(:reset_password_sent_at, 50.days.ago)
    get :show, id: user.id, onetime_token: user.reset_password_token
    
    should redirect_to(new_person_session_path)
    assigns(:current_person).should_not be_present
  end
  
  it "cannot sign in with wrong token" do
    user.generate_reset_password_token!
    get :show, id: user.id, onetime_token: 'yadayada'
    
    should redirect_to(new_person_session_path)
    assigns(:current_person).should_not be_present
  end
end
