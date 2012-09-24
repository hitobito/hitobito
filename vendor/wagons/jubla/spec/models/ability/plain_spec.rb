require 'spec_helper'


# Specs for managing and viewing people


describe Ability do
  
  subject { ability }
  let(:ability) { Ability.new(role.person.reload) }


  describe :layer_full do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }

    it "may modify any public role in lower layers" do
      other = Fabricate(Group::Flock::CampLeader.name.to_sym, group: groups(:bern))
      should be_able_to(:modify, other.person.reload)
      should be_able_to(:update, other)
    end
    
    it "may modify externals in the same layer" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:ch))
      should be_able_to(:modify, other.person)
      should be_able_to(:update, other)
    end
    
    it "may not view any children in lower layers" do
      other = Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix))
      should_not be_able_to(:show_details, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may not view any externals in lower layers" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be))
      should_not be_able_to(:show_details, other.person)
      should_not be_able_to(:update, other)
    end
    
  end
  
  
  describe 'layer_full in flock' do
    let(:role) { Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern)) }
    
    it "may create other users" do
      should be_able_to(:create, Person)
    end

    it "may modify any public role in same layer" do
      other = Fabricate(Group::Flock::CampLeader.name.to_sym, group: groups(:bern))
      should be_able_to(:modify, other.person)
      should be_able_to(:update, other)
    end
    
    it "may not view any public role in upper layers" do
      other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
      should_not be_able_to(:show_details, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may not view any public role in other flocks" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should_not be_able_to(:show_details, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may modify externals in his flock" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
      should be_able_to(:modify, other.person)
      should be_able_to(:update, other)
    end
    
    it "may modify children in his flock" do
      other = Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix))
      should be_able_to(:modify, other.person)
      should be_able_to(:update, other)
    end
    
    it "may not view any externals in upper layers" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be))
      should_not be_able_to(:show_details, other.person)
      should_not be_able_to(:update, other)
    end
  end
  
    
  describe :layer_read do
    let(:role) do
      # member with additional group_admin role
      role1 = Fabricate(Group::StateBoard::Supervisor.name.to_sym, group: groups(:be_board))
      Fabricate(Jubla::Role::GroupAdmin.name.to_sym, group: groups(:be_board), person: role1.person)
    end
    
    it "may view details of himself" do
      should be_able_to(:show_details, role.person)
    end
    
    it "may modify himself" do
      should be_able_to(:modify, role.person)
    end
    
    it "may modify its role" do
      should be_able_to(:update, role)
    end
        
    it "may create other users as group admin" do
      should be_able_to(:create, Person)
    end
    
    it "may view any public role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should be_able_to(:show_details, other.person)
    end
    
    it "may not modify any role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should_not be_able_to(:modify, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may view any externals in same layer" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_security))
      should be_able_to(:show_details, other.person)
    end
    
    it "may modify any role in same group" do
      other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
      should be_able_to(:modify, other.person)
      should be_able_to(:update, other)
    end
    
    it "may not view details of any public role in upper layers" do
      other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board))
      should_not be_able_to(:show_details, other.person)
    end
    
    it "may view any public role in groups below" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should be_able_to(:show_details, other.person.reload)
    end
    
    it "may not modify any public role in groups below" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should_not be_able_to(:modify, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may not view any externals in groups below" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:thun))
      should_not be_able_to(:show, other.person)
    end
  end
  
  describe :contact_data do
    let(:role) { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }
    
    it "may view details of himself" do
      should be_able_to(:show_details, role.person)
    end
    
    it "may modify himself" do
      should be_able_to(:modify, role.person)
    end
    
    it "may not modify his role" do
      should_not be_able_to(:update, role)
    end
    
    it "may not create other users" do
      should_not be_able_to(:create, Person)
    end
    
    it "may view others in same group" do
      other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
      should be_able_to(:show, other.person)
    end
        
    it "may not view details of others in same group" do
      other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
      should_not be_able_to(:show_details, other.person)
    end
    
    it "may not modify others in same group" do
      other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
      should_not be_able_to(:modify, other.person)
      should_not be_able_to(:update, other)
    end

    it "may show any public role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should be_able_to(:show, other.person)
    end
    
    it "may not view details of public role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should_not be_able_to(:show_details, other.person)
    end
    
    it "may not modify any role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should_not be_able_to(:modify, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may not view externals in other group of same layer" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_security))
      should_not be_able_to(:show, other.person)
    end
    
    it "may view any public role in upper layers" do
      other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board))
      should be_able_to(:show, other.person)
    end
    
    it "may not view details of any public role in upper layers" do
      other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board))
      should_not be_able_to(:show_details, other.person)
    end
    
    it "may view any public role in groups below" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should be_able_to(:show, other.person)
    end
    
    it "may not modify any public role in groups below" do
      other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:thun))
      should_not be_able_to(:modify, other.person)
      should_not be_able_to(:update, other)
    end
    
    it "may not view any externals in groups below" do
      other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:thun))
      should_not be_able_to(:show, other.person)
    end
  end
  
  describe :login do
    let(:role) { Fabricate(Group::WorkGroup::Member.name.to_sym, group: groups(:be_state_camp)) }
        
    it "may view details of himself" do
      should be_able_to(:show_details, role.person)
    end
    
    it "may modify himself" do
      should be_able_to(:modify, role.person)
    end
    
    it "may not modify his role" do
      should_not be_able_to(:update, role)
    end
        
    it "may not create other users" do
      should_not be_able_to(:create, Person)
    end
    
    it "may view others in same group" do
      other = Fabricate(Group::WorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
      should be_able_to(:show, other.person)
    end
    
    it "may not view details of others in same group" do
      other = Fabricate(Group::WorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
      should_not be_able_to(:show_details, other.person)
    end
        
    it "may not view public role in same layer" do
      other = Fabricate(Group::ProfessionalGroup::Member.name.to_sym, group: groups(:be_security))
      should_not be_able_to(:show, other.person)
    end
  end
  
  context "create Group" do
    subject { ability }
    context "layer full" do
      let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
      
      context "without specific group" do
        it "may not create subgroup" do
          should_not be_able_to(:create, Group.new)
        end
      end
      
      context "in own group" do
        let(:group) { role.group }
        it "may create subgroup" do
          should be_able_to(:create, group.children.new)
        end
      end
      
      context "in group from lower layer" do
        let(:group) { groups(:bern) }
        it "may create subgroup" do
          should be_able_to(:create, group.children.new)
        end
      end
    end
    
    context "group full" do
      let(:role) { Fabricate(Jubla::Role::GroupAdmin.name.to_sym, group: groups(:be_security)) }
      
      context "in own group" do
        let(:group) { role.group }
        it "may not create subgroup" do
          should_not be_able_to(:create, group.children.new)
        end
      end
      
      context "without specific group" do
        it "may not create subgroup" do
          should_not be_able_to(:create, Group.new)
        end
      end
      
      context "in other group from same layer" do
        let(:group) { groups(:be_board) }
        it "may not create subgroup" do
          should_not be_able_to(:create, group.children.new)
        end
      end
      
      context "in group from lower layer" do
        let(:group) { groups(:bern) }
        it "may not create subgroup" do
          should_not be_able_to(:create, group.children.new)
        end
      end
      
      context "in group from other layer" do
        let(:group) { groups(:no_board) }
        it "may not create subgroup" do
          should_not be_able_to(:create, group.children.new)
        end
      end
    end

  end
end
