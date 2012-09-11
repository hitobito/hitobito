require 'spec_helper'


# Specs for listing and searching people


describe Ability::WithGroup do
  
  let(:ability) { Ability::WithGroup.new(role.person, group) }
  
  context "create Group" do
    subject { ability }
    context "layer full" do
      let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
      
      context "in own group" do
        let(:group) { role.group }
        it "may create subgroup" do
          should be_able_to(:create, Group)
        end
      end
      
      context "in group from lower layer" do
        let(:group) { groups(:bern) }
        it "may create subgroup" do
          should be_able_to(:create, Group)
        end
      end
    end
    
    context "group full" do
      let(:role) { Fabricate(Jubla::Role::GroupAdmin.name.to_sym, group: groups(:be_security)) }
      
      context "in own group" do
        let(:group) { role.group }
        it "may create subgroup" do
          should_not be_able_to(:create, Group)
        end
      end
      
      context "in other group from same layer" do
        let(:group) { groups(:be_board) }
        it "may not create subgroup" do
          should_not be_able_to(:create, Group)
        end
      end
      
      context "in group from lower layer" do
        let(:group) { groups(:bern) }
        it "may not create subgroup" do
          should_not be_able_to(:create, Group)
        end
      end
      
      context "in group from other layer" do
        let(:group) { groups(:no_board) }
        it "may not create subgroup" do
          should_not be_able_to(:create, Group)
        end
      end
    end

  end
  
  [:index, :layer_search, :deep_search].each do |action|
    context action do
      subject { Person.accessible_by(ability, action) }
      let(:action) { action }
  
      describe :layer_full do
        let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
        
        it "has layer full permission" do
          role.permissions.should include(:layer_full)
        end
      
        context "own group" do
          let(:group) { role.group }
          
          it "may get himself" do
            should include(role.person)
          end
          
          it "may get people in his group" do
            other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board))
            should include(other.person)
          end
          
          if action == :deep_search
            it "may not get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:federal_board))
              should_not include(other.person)
            end
          else
            it "may get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:federal_board))
              should include(other.person)
            end
          end
        end
        
        context "lower group" do
          let(:group) { groups(:be_board) }
          
          it "may get visible people" do
            other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
          
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
            should_not include(other.person)
          end
        end
      end
    
      
      describe :layer_read do
        let(:role) { Fabricate(Group::StateBoard::Supervisor.name.to_sym, group: groups(:be_board)) }
        
        it "has layer read permission" do
          role.permissions.should include(:layer_read)
        end
                
        context "own group" do
          let(:group) { role.group }
          
          it "may get himself" do
            should include(role.person)
          end
          
          it "may get people in his group" do
            other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
          
          if action == :deep_search
            it "may not get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
              should_not include(other.person)
            end
          else
            it "may get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
              should include(other.person)
            end
          end
        end
              
        context "group in same layer" do
          let(:group) { groups(:be_agency) }
          
          it "may get people" do
            other = Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency))
            should include(other.person)
          end
          
          if action == :deep_search
            it "may not get external people" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_agency))
              should_not include(other.person)
            end
          else
            it "may get external people" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_agency))
              should include(other.person)
            end
          end
        end
        
        context "lower group" do
          let(:group) { groups(:bern) }
          
          it "may get visible people" do
            other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern))
            should include(other.person)
          end
          
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end
              
        context "child group" do
          let(:group) { groups(:asterix) }
  
          it "may not get children" do
            other = Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix))
            should_not include(other.person)
          end
        end
        
      end
      
      describe :group_full do
        let(:role) { Fabricate(Jubla::Role::GroupAdmin.name.to_sym, group: groups(:be_board)) }
        
        it "has group full permission" do
          role.permissions.should include(:group_full)
        end
                  
        context "own group" do
          let(:group) { role.group }
          
          it "may get himself" do
            should include(role.person)
          end
          
          it "may get people in his group" do
            other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
          
          if action == :deep_search
            it "may not get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
              should_not include(other.person)
            end
          else
            it "may get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
              should include(other.person)
            end
          end
        end
              
        context "group in same layer" do
          let(:group) { groups(:be_agency) }
          
          it "may not get people" do
            other = Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency))
            should_not include(other.person)
          end
          
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_agency))
            should_not include(other.person)
          end
        end
        
        context "lower group" do
          let(:group) { groups(:bern) }
          
          it "may not get visible people" do
            other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end
          
      end
      
      describe :contact_data do
        let(:role) { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }
        
        it "has contact data permission" do
          role.permissions.should include(:contact_data)
        end
                  
        context "own group" do
          let(:group) { role.group }
          
          it "may get himself" do
            should include(role.person)
          end
          
          it "may get people in his group" do
            other = Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
          
          if action == :index
            it "may get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
              should include(other.person)
            end
          else
            it "may not get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
              should_not include(other.person)
            end
          end
        end
              
        context "group in same layer" do
          let(:group) { groups(:be_state_camp) }
          
          it "may get people with contact data" do
            other = Fabricate(Group::WorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
            should include(other.person)
          end
          
          it "may not get people without contact data" do
            other = Fabricate(Group::WorkGroup::Member.name.to_sym, group: groups(:be_state_camp))
            should_not include(other.person)
          end
          
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_state_camp))
            should_not include(other.person)
          end
        end
        
        context "lower group" do
          let(:group) { groups(:bern) }
          
          it "may get people with contact data" do
            other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern))
            should include(other.person)
          end
          
          it "may not get people without contact data" do
            other = Fabricate(Group::Flock::Guide.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
          
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end
            
      end
      
      
      describe :login do
        let(:role) { Fabricate(Group::WorkGroup::Member.name.to_sym, group: groups(:be_state_camp)) }
        
        it "has only login permission" do
          role.permissions.should == [:login]
        end
      
        context "own group" do
          let(:group) { role.group }
          
          it "may get himself" do
            should include(role.person)
          end
          
          it "may get people in his group" do
            other = Fabricate(Group::WorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
            should include(other.person)
          end
          
          if action == :deep_search
            it "may not get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_state_camp))
              should_not include(other.person)
            end
          else
            it "may get external people in his group" do
              other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_state_camp))
              should include(other.person)
            end
          end
        end
              
        context "group in same layer" do
          let(:group) { groups(:be_board) }
          
          it "may not get people with contact data" do
            other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
            should_not include(other.person)
          end
  
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
            should_not include(other.person)
          end
        end
        
        context "lower group" do
          let(:group) { groups(:bern) }
          
          it "may not get people with contact data" do
            other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
          
          it "may not get external people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end
          
      end
    end
  end
end