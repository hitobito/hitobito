require 'spec_helper'

describe Group::Flock do
  subject { groups(:bern) } 

  let(:state_board_member) { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }

  context "#to_s" do
    its(:to_s) { should == 'Jungwacht Bern' }
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
    let(:state_coach) { Fabricate(Group::State::Coach.name.to_sym, group: groups(:be)) }
    let(:other_state_coach) { Fabricate(Group::State::Coach.name.to_sym, group: groups(:no)) }
    let(:region_coach) { Fabricate(Group::Region::Coach.name.to_sym, group: groups(:city)) }

    its(:available_coaches) { should include(state_coach.person) } 
    its(:available_coaches) { should include(region_coach.person) } 
    its(:available_coaches) { should_not include(other_state_coach.person) } 
    its(:available_coaches) { should_not include(state_board_member.person) } 
  end
  
  context "coach may be set" do
    let(:state_coach) { Fabricate(Group::State::Coach.name.to_sym, group: groups(:be)) }
    
    it "persists coach" do
      subject.coach_id = state_coach.person_id
      subject.save!
      
      Group.find(subject.id).coach_id.should == state_coach.person_id
      Group.find(subject.id).coach.should == state_coach.person
    end
    
    it "removes existing coach if id is set blank" do
      subject.coach_id = state_coach.person_id
      subject.save!
      
      subject.coach_id = ''
      expect { subject.save! }.to change { Role.count }.by(-1) 
    end
    
    it "does not touch existing coach if id is not changed" do
      subject.coach_id = state_coach.person_id
      subject.save!
      
      subject.coach_id = state_coach.person_id
      expect { subject.save! }.not_to change { Role.count }
    end
    
    it "removes existing and creates new coach on reassignment" do
      subject.coach_id = state_coach.person_id
      subject.save!
      
      new_coach = Fabricate(:person)
      subject.coach_id = new_coach.id
      expect { subject.save! }.not_to change { Role.count }
      Group.find(subject.id).coach_id.should == new_coach.id
      subject.roles.where(person_id: state_coach.person_id).should_not be_exists
    end
  end
end
