require 'spec_helper'
describe GroupsController do
  let(:flock) { groups(:bern) }
  let(:leader) { Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person }

  before { sign_in(leader) }

  it "#edit - loads advisors and coaches" do
    get :edit, id: flock.id
    assigns(:coaches).should eq flock.available_coaches.only_public_data.order_by_name
    assigns(:advisors).should eq flock.available_advisors.only_public_data.order_by_name
  end

  it "#new - loads advisors and coaches" do
    get :new, group: { parent_id: flock.parent.id, type: flock.type }
    assigns(:coaches).should_not be_present
    assigns(:advisors).should_not be_present
  end

end
