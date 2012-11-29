require 'spec_helper'
describe Ability::Various do
  
  let(:user) { role.person}
  let(:group) { role.group }
  let(:qualification) { Fabricate(:qualification, person: person) }

  subject { Ability.new(user.reload) }

  describe "FederalBoard Member" do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
    
    context "on StateAgency Member" do
      let(:person) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)).person }

      it "can create and destroy" do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end

    context "on FederalBoard Member" do
      let(:person) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)).person }

      it "can create and destroy" do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end
  end


  describe "StateAgency Member" do
    let(:role) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)) }

    context "on StateAgency Member" do
      let(:person) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)).person }

      it "can create and destroy" do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end

    context "on FederalBoard Member" do
      let(:person) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)).person }

      it "cannot create and destroy" do
        should_not be_able_to(:create, qualification)
        should_not be_able_to(:destroy, qualification)
      end
    end
    
    context "on Flock Leader" do
      let(:person) { Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern)).person }

      it "can create and destroy" do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end
  end


end

