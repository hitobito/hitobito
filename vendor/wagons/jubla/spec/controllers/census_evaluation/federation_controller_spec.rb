require 'spec_helper'

describe CensusEvaluation::FederationController do
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:no)   { groups(:no) }
  let(:bern) { groups(:bern) }
  let(:thun) { groups(:thun) }
  let(:innerroden) { groups(:innerroden) }
  let(:zh)   { Fabricate(Group::State.name, name: 'Zurich', parent: ch) }

  before do
    Census.create!(year: 2012, start_at: Date.new(2012,8,1))
    
    create_count(bern, be, 1985, leader_m: 3, leader_f: 1)
    create_count(bern, be, 1988, leader_f: 1, child_m: 1)
    create_count(bern, be, 1997, child_m: 2, child_f: 4)
    
    create_count(thun, be, 1984, leader_m: 1, leader_f: 1)
    create_count(thun, be, 1985, leader_m: 1)
    create_count(thun, be, 1999, child_m: 3, child_f: 1)
    
    create_count(innerroden, no, 1984, leader_m: 2, leader_f: 1)
    create_count(innerroden, no, 1999, child_m: 2, child_f: 4)
    
    zh #create
    
    sign_in(people(:top_leader))
  end
  
  
  describe 'GET total' do
    
    before { get :total, id: ch.id }
    
    it "assigns counts" do
      counts = assigns(:counts)
      counts.keys.should =~ [be.id, no.id]
      counts[be.id].total.should == 19
      counts[no.id].total.should == 9
    end
    
    it "assigns total" do
      assigns(:total).should be_kind_of(MemberCount)
    end
    
    it "assigns sub groups" do
      assigns(:sub_groups).should == [be, no, zh]
    end
    
    it "assigns flocks" do
      assigns(:flocks).should == {
        be.id => {confirmed: 2, total: 3},
        no.id => {confirmed: 1, total: 2},
        zh.id => {confirmed: 0, total: 0},
      }.with_indifferent_access
    end
  end
  
  def create_count(flock, state, born_in, attrs = {})
    count = MemberCount.new
    count.flock_id = flock.id
    count.state_id = state.id
    count.year = 2012
    count.born_in = born_in
    count.attributes = attrs
    count.save!
  end
  
end
