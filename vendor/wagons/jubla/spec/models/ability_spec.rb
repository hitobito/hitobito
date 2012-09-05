require 'spec_helper'

describe Ability do
  
  subject { ability }
  let(:ability) { Ability.new(role.person) }


  describe Group::FederalBoard::Member do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }

    it "may manage any public role in lower layers" do
      other = Fabricate(Group::Flock::CampLeader.name.to_sym, group: groups(:bern))
      should be_able_to(:manage, other.person)
    end
    
    it "may manage externals in the same layer" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:ch))
      should be_able_to(:manage, other.person)
    end
    
    it "may not view any children in lower layers" do
      other = Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix))
      should_not be_able_to(:show, other.person)
    end
    
    it "may not view any externals in lower layers" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be))
      should_not be_able_to(:show, other.person)
    end
  end
  
  
  describe Group::Flock::Leader do
    let(:role) { Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern)) }

    it "may manage any public role in same layer" do
      other = Fabricate(Group::Flock::CampLeader.name.to_sym, group: groups(:bern))
      should be_able_to(:manage, other.person)
    end
    
    it "may not view any public role in upper layers" do
      other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
      should_not be_able_to(:show, other.person)
    end
    
    it "may not view any public role in other flocks" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should_not be_able_to(:show, other.person)
    end
    
    it "may manage externals in his flock" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
      should be_able_to(:manage, other.person)
    end
    
    it "may view children in his flock" do
      other = Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix))
      should be_able_to(:manage, other.person)
    end
    
    it "may not view any externals in upper layers" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be))
      should_not be_able_to(:show, other.person)
    end
  end
end
