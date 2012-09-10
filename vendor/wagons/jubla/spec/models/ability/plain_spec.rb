require 'spec_helper'


# Specs for managing and viewing people


describe Ability::Plain do
  
  subject { ability }
  let(:ability) { Ability::Plain.new(role.person) }


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
    
    it "may manage children in his flock" do
      other = Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix))
      should be_able_to(:manage, other.person)
    end
    
    it "may not view any externals in upper layers" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be))
      should_not be_able_to(:show, other.person)
    end
  end
  
    
  describe Group::StateBoard::Supervisor do
    let(:role) do
      # member with additional group_admin role
      role1 = Fabricate(Group::StateBoard::Supervisor.name.to_sym, group: groups(:be_board))
      Fabricate(Jubla::Role::GroupAdmin.name.to_sym, group: groups(:be_board), person: role1.person)
    end

    it "may view any public role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should be_able_to(:show, other.person)
    end
    
    it "may not manage any role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should_not be_able_to(:manage, other.person)
    end
    
    it "may view any externals in same layer" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_security))
      should be_able_to(:show, other.person)
    end
    
    it "may manage any role in same group" do
      other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
      should be_able_to(:manage, other.person)
    end
    
    it "may not view any public role in upper layers" do
      other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board))
      should_not be_able_to(:show, other.person)
    end
    
    it "may view any public role in groups below" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should be_able_to(:show, other.person)
    end
    
    it "may not manage any public role in groups below" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should_not be_able_to(:manage, other.person)
    end
    
    it "may not view any externals in groups below" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:thun))
      should_not be_able_to(:show, other.person)
    end
  end
end
