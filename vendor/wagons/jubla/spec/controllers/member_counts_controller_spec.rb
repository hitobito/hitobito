require 'spec_helper'

describe MemberCountsController do
  
  let(:flock) { groups(:bern) }
  
  before { sign_in(people(:top_leader)) }
  
  describe "GET edit" do
    context "in 2012" do
      before { get :edit, group_id: flock.id, year: 2012 }
      
      it "assigns counts" do
        assigns(:member_counts).should have(3).items
        assigns(:group).should == flock
      end
    end
    
    it "without year raises exception" do
      expect { get :edit, group_id: flock.id }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "PUT update" do
    before do
      put :update, group_id: flock.id, year: 2012, member_count:
                    { member_counts(:bern_1985).id => {leader_f: 3, leader_m: 1, child_f: '', child_m: '0'}, 
                      member_counts(:bern_1988).id => {leader_f: 2, leader_m: 0, child_f: nil, child_m: 1},
                      member_counts(:bern_1997).id => {leader_f: 0, leader_m: 0, child_f: 5, child_m: 2},
                    }
      
    end

    it { should redirect_to(census_flock_group_path(flock, year: 2012)) }
      
    it "should save counts" do
      assert_member_counts(:bern_1985, 3, 1, nil, 0)
      assert_member_counts(:bern_1988, 2, 0, nil, 1)
      assert_member_counts(:bern_1997, 0, 0, 5, 2)
    end
  end
  
      
  def assert_member_counts(count_key, leader_f, leader_m, child_f, child_m)
    count = member_counts(count_key).reload
    count.leader_f.should == leader_f
    count.leader_m.should == leader_m
    count.child_f.should == child_f
    count.child_m.should == child_m
  end
  
end
