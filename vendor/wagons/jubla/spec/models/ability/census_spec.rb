require 'spec_helper'

describe Ability do
  
  let(:user) { role.person }
  let(:group) { role.group }
  let(:flock) { groups(:bern) }

  subject { Ability.new(user.reload) }
  
  describe "FederalBoard Member" do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
    
    it "may update member counts" do
      should be_able_to(:update_member_counts, flock)
    end
    
    it "may create member counts" do
      should be_able_to(:create_member_counts, flock)
    end
    
    it "may approve population" do
      should be_able_to(:approve_population, flock)
    end
    
    it "may view census for flock" do
      should be_able_to(:evaluate_census, flock)
    end
    
    it "may view census for state" do
      should be_able_to(:evaluate_census, flock.state)
    end
    
    it "may view census for federation" do
      should be_able_to(:evaluate_census, group)
    end
  end
  
  describe "State Agency Leader" do
    let(:role) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)) }
    
    it "may update member counts" do
      should be_able_to(:update_member_counts, flock)
    end
    
    it "may create member counts" do
      should be_able_to(:create_member_counts, flock)
    end
   
    it "may approve population" do
      should be_able_to(:approve_population, flock)
    end
    
    it "may view census for flock" do
      should be_able_to(:evaluate_census, flock)
    end
    
    it "may view census for state" do
      should be_able_to(:evaluate_census, flock.state)
    end
    
    it "may not view census for federation" do
      should_not be_able_to(:evaluate_census, groups(:ch))
    end
  
    context "for other state" do
      let(:role) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:no_agency)) }
      
          
      it "may not update member counts" do
        should_not be_able_to(:update_member_counts, flock)
      end
      
      it "may not approve population" do
        should_not be_able_to(:approve_population, flock)
      end
      
      it "may not view census for flock" do
        should_not be_able_to(:evaluate_census, flock)
      end
    end
  end
  
  
  describe "Flock Leader" do
    let(:role) { Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern)) }
    
    it "may not update member counts" do
      should_not be_able_to(:update_member_counts, flock)
    end
    
    it "may create member counts" do
      should be_able_to(:create_member_counts, flock)
    end
    
    it "may approve population" do
      should be_able_to(:approve_population, flock)
    end
    
    it "may view census for flock" do
      should be_able_to(:evaluate_census, flock)
    end
    
    it "may not view census for state" do
      should_not be_able_to(:evaluate_census, flock.state)
    end
    
    it "may not view census for federation" do
      should_not be_able_to(:evaluate_census, groups(:ch))
    end
  end
end