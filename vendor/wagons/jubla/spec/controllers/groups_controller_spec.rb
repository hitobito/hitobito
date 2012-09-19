require 'spec_helper'
describe GroupsController do
  let(:flock) { groups(:bern) }
  let(:leader) { Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person }


  describe "#edit" do
    render_views
    it "renders ok" do
      sign_in(leader)
      get :show, id: flock.id
      puts response.body
    end
    
  end
  
end
