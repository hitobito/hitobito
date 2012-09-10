require 'spec_helper'


# Specs for listing and searching people


describe Ability::WithGroup do
  
  subject { Person.accessible_by(ability, action) }
  let(:ability) { Ability::WithGroup.new(role.person, group) }
  let(:group) { role.group }
  
  describe Group::FederalBoard::Member do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
    
    context "index" do
      let(:action) { :index }
      
      it "may index himself" do
        should include(role.person)
      end
      
      it "may index people in his group" do
        other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board))
        should include(other.person)
      end
    end
  end
  
end