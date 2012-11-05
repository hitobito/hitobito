require 'spec_helper'

describe Group::Flock do
  subject { groups(:bern) } 

  let(:state_board_member) { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }

  context "#to_s" do
    its(:to_s) { should == 'Bern' }
    
    context "with kind" do
      let(:kind) { Group::Flock::AVAILABLE_KINDS.first  }
      before { subject.kind = kind}
      
      its(:to_s) { should == "#{kind} Bern" }
    end
  end
  
  context "#available_advisors includes members from upper layers, filters affiliate roles" do
    let(:city_board_leader) { Fabricate(Group::RegionalBoard::Leader.name.to_sym, group: groups(:city_board)) }
    let(:external_cbm) { Fabricate(Jubla::Role::External.name.to_sym, group: groups(:city_board)) }
    let(:flock_member) { Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern)) }

    its(:available_advisors) { should include(state_board_member.person) } 
    its(:available_advisors) { should include(city_board_leader.person) } 
    its(:available_advisors) { should_not include(external_cbm.person) } 
    its(:available_advisors) { should_not include(flock_member.person) } 
  end

  context "#available_coaches includes coach roles from upper layers" do
    let(:state_coach) { Fabricate(Jubla::Role::Coach.name.to_sym, group: groups(:be)) }
    let(:other_state_coach) { Fabricate(Jubla::Role::Coach.name.to_sym, group: groups(:no)) }
    let(:region_coach) { Fabricate(Jubla::Role::Coach.name.to_sym, group: groups(:city)) }

    its(:available_coaches) { should include(state_coach.person) } 
    its(:available_coaches) { should include(region_coach.person) } 
    its(:available_coaches) { should_not include(other_state_coach.person) } 
    its(:available_coaches) { should_not include(state_board_member.person) } 
  end
end
