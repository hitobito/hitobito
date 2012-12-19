require 'spec_helper'
describe Group::MoveController do

  render_views

  let(:user) { people(:top_leader) }
  let(:group) { groups(:bottom_group_one_one) }
  let(:target) { groups(:bottom_layer_two) }

  before { sign_in(user) }

  context "GET :select" do
    it "assigns candidates" do
      get :select, id: group.id
      assigns(:candidates)['Gruppe'].should include target
    end
  end

  context "POST :perform" do
    it "performs moving" do
      post :perform, id: group.id, mover: { group: target.id }
      flash[:notice].should eq "#{group} wurde nach #{target} verschoben."
      should redirect_to(group)
    end
  end

end

