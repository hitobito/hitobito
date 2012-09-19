require 'spec_helper'
describe GroupsController do
  let(:flock) { groups(:bern) }
  let(:leader) { Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person }


  describe "#edit" do
    render_views
    it "renders ok" do
      sign_in(leader)
      get :edit, id: flock.id
      response.body.should =~ /Jubla Versicherung/m
    end
    
  end
  
end
