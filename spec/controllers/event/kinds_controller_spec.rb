require 'spec_helper'

describe Event::KindsController do
   
  let(:destroyed) { Event::Kind.unscoped.find(ActiveRecord::Fixtures.identify(:old)) }
   
  before { sign_in(people(:top_leader)) }
   
  it "POST update resets destroy flag when updating deleted kinds" do
    destroyed.should be_destroyed
    post :update, id: destroyed.id
    destroyed.reload.should_not be_destroyed
  end
  
  it "GET index lists destroyed entries last" do
    get :index
    assigns(:kinds).last.should == destroyed
  end
  
end
