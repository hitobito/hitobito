require 'spec_helper'

describe MemberCount do 
  
  let(:be)   { groups(:be) }
  let(:no)   { groups(:no) }
  let(:bern) { groups(:bern) }
  let(:thun) { groups(:thun) }
  let(:innerroden) { groups(:innerroden) }
  
  describe ".total_by_flocks" do
    
    subject { MemberCount.total_by_flocks(2012, be).to_a }
    
    it "counts totals" do
      should have(2).items
      
      bern_count = subject.detect {|c| c.flock_id == bern.id }
      assert_member_counts(bern_count, 2, 3, 4, 3)
      
      thun_count = subject.detect {|c| c.flock_id == thun.id }
      assert_member_counts(thun_count, 1, 2, 1, 3)
    end
  end
  
  describe ".total_for_flock" do
    subject { MemberCount.total_for_flock(2012, bern) }
    
    it "counts totals" do
      assert_member_counts(subject, 2, 3,4, 3)
    end
  end
  
  describe ".total_for_federation" do
    subject { MemberCount.total_for_federation(2012) }
    
    it "counts totals" do
      assert_member_counts(subject, 4, 7, 9, 8)
    end
  end
  
  describe ".total_by_states" do
    
    subject { MemberCount.total_by_states(2012).to_a }
    
    it "counts totals" do
      should have(2).items
      
      be_count = subject.detect {|c| c.state_id == be.id }
      assert_member_counts(be_count, 3, 5, 5, 6)
      
      no_count = subject.detect {|c| c.state_id == no.id }
      assert_member_counts(no_count, 1, 2, 4, 2)
    end
  end
  
  describe ".details_for_flock" do
    subject { MemberCount.details_for_flock(2012, bern).to_a }
    
    it "lists all years" do
      subject.collect(&:born_in).should == [1985, 1988, 1997]
      
      assert_member_counts(subject[0], 1, 3, nil, nil)
      assert_member_counts(subject[1], 1, nil, nil, 1)
      assert_member_counts(subject[2], nil, nil, 4, 2)
    end
  end
  
  describe ".details_for_state" do
    subject { MemberCount.details_for_state(2012, be).to_a }
    
    it "lists all years" do
      subject.collect(&:born_in).should == [1984, 1985, 1988, 1997, 1999]
      
      assert_member_counts(subject[0], 1, 1, nil, nil) # 1984
      assert_member_counts(subject[1], 1, 4, nil, nil) # 1985
      assert_member_counts(subject[2], 1, nil, nil, 1) # 1988
      assert_member_counts(subject[3], nil, nil, 4, 2) # 1997
      assert_member_counts(subject[4], nil, nil, 1, 3) # 1999
    end
  end
  
  describe ".details_for_federation" do
    subject { MemberCount.details_for_federation(2012).to_a }
    
    it "lists all years" do
      subject.collect(&:born_in).should == [1984, 1985, 1988, 1997, 1999]
      
      assert_member_counts(subject[0], 2, 3, nil, nil) # 1984
      assert_member_counts(subject[1], 1, 4, nil, nil) # 1985
      assert_member_counts(subject[2], 1, nil, nil, 1) # 1988
      assert_member_counts(subject[3], nil, nil, 4, 2) # 1997
      assert_member_counts(subject[4], nil, nil, 5, 5) # 1999
    end
  end
  
  def assert_member_counts(count, leader_f, leader_m, child_f, child_m)
    count.leader_f.should == leader_f
    count.leader_m.should == leader_m
    count.child_f.should == child_f
    count.child_m.should == child_m
  end
  
end
