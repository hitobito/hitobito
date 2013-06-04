require 'spec_helper'


# Specs for listing and searching people
describe PersonAccessibles do


  [:index, :layer_search, :deep_search, :global].each do |action|
    context action do
      let(:action) { action }
      let(:user)   { role.person.reload }
      let(:ability) { PersonAccessibles.new(user, action == :index ? group : nil) }

      let(:all_accessibles) do
        people = Person.accessible_by(ability)
        case action
        when :index then people
        when :layer_search then people.in_layer(group.layer_group)
        when :deep_search then people.in_or_below(group.layer_group)
        when :global then people
        end
      end


      subject { all_accessibles }

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

          it "may get affiliate people in his group" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:federal_board))
            should include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:be_board) }

          it "may get visible people" do
            other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end

          it "may not get affiliate people" do
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

          it "may get affiliate people in his group" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:be_agency) }

          it "may get people" do
            other = Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency))
            should include(other.person)
          end

          it "may get affiliate people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_agency))
            should include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bern) }

          it "may get visible people" do
            other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern))
            should include(other.person)
          end

          it "may not get affiliate people" do
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

          it "may get affiliate people in his group" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:be_agency) }

          it "may not get people" do
            other = Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency))
            should_not include(other.person)
          end

          it "may not get affiliate people" do
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

          it "may get affiliate people in his group" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_board))
            should include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:be_state_camp) }

          it "may get people with contact data" do
            other = Fabricate(Group::StateWorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
            should include(other.person)
          end

          it "may not get people without contact data" do
            other = Fabricate(Group::StateWorkGroup::Member.name.to_sym, group: groups(:be_state_camp))
            should_not include(other.person)
          end

          it "may not get affiliate people" do
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

          it "may not get affiliate people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end

      end


      describe :group_read do
        let(:role) { Fabricate(Group::StateWorkGroup::Member.name.to_sym, group: groups(:be_state_camp)) }

        it "has only login permission" do
          role.permissions.should == [:group_read]
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            should include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::StateWorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
            should include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_state_camp))
            should include(other.person)
          end

          it "may get alumni in his group" do
            other = Fabricate(Jubla::Role::Alumnus.name.to_sym, group: groups(:be_state_camp))
            should include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:be_board) }

          it "may not get people with contact data" do
            other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
            should_not include(other.person)
          end

          it "may not get affiliate people" do
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

          it "may not get affiliate people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end

      end


      describe 'no permissions' do
        let(:role) { Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_state_camp)) }

        it "has no permissions" do
          role.permissions.should == []
        end

        context "own group" do
          let(:group) { role.group }

          if action == :index
            it "may not get himself" do
              should_not include(role.person)
            end
          else
            it "may get himself" do
              should include(role.person)
            end
          end

          it "may not get people in his group" do
            other = Fabricate(Group::StateWorkGroup::Leader.name.to_sym, group: groups(:be_state_camp))
            should_not include(other.person)
          end

          it "may not get external people in his group" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: groups(:be_state_camp))
            should_not include(other.person)
          end

          it "may not get alumni in his group" do
            other = Fabricate(Jubla::Role::Alumnus.name.to_sym, group: groups(:be_state_camp))
            should_not include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:be_board) }

          it "may not get people with contact data" do
            other = Fabricate(Group::StateBoard::Leader.name.to_sym, group: groups(:be_board))
            should_not include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bern) }

          it "may not get people with contact data" do
            other = Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern))
            should_not include(other.person)
          end
        end

      end

      describe :root do
        let(:user) { people(:root) }

        context "every group" do
          let(:group) { groups(:federal_board) }

          it "may get all people" do
            other = Fabricate(Group::FederalBoard::Member.name.to_sym, group: group)
            should include(other.person)
          end

          it "may get affiliate people" do
            other = Fabricate(Jubla::Role::External.name.to_sym, group: group)
            should include(other.person)
          end
        end

        if action == :global
          it "may get herself" do
            should include(user)
          end

          it "may get people outside groups" do
            other = Fabricate(:person)
            should include(other)
          end
        end

      end

    end
  end
end