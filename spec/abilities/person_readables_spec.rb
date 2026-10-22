#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

# Specs for listing and searching people
describe PersonReadables do
  [:index, :layer_search, :deep_search, :global].each do |action|
    context action do
      let(:action) { action }
      let(:user) { role.person.reload }
      let(:ability) { PersonReadables.new(user, (action == :index) ? group : nil) }

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

      context :layer_and_below_full do
        let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

        it "has layer_and_below_full permission" do
          expect(role.permissions).to include(:layer_and_below_full)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may get visible people" do
            other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.not_to include(other.person)
          end
        end
      end

      context :see_invisible_from_above do
        let(:role) { Fabricate(Group::TopGroup::InvisiblePeopleManager.name, group: groups(:top_group)) }

        it "has see_invisible_from_above permission" do
          expect(role.permissions).to include(:see_invisible_from_above)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get people with visible_from_above=true" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            expect(other).to be_visible_from_above
            is_expected.to include(other.person)
          end

          it "may get people with visible_from_above=false" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            expect(other).not_to be_visible_from_above
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may get people with visible_from_above=true" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
            expect(other).to be_visible_from_above
            is_expected.to include(other.person)
          end

          it "may get people with visible_from_above=false" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            expect(other).not_to be_visible_from_above
            is_expected.to include(other.person)
          end
        end
      end

      context :layer_and_below_read do
        let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

        it "has layer_and_below_read permission" do
          expect(role.permissions).to include(:layer_and_below_read)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:toppers) }

          it "may get people" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may get visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "bottom group" do
          let(:group) { groups(:bottom_group_one_one) }

          it "may not get non-visible" do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :layer_full do
        let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

        it "has layer_full permission" do
          expect(role.permissions).to include(:layer_full)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not get visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one))
            is_expected.not_to include(other.person)
          end
        end
      end

      context :layer_read do
        let(:role) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: groups(:top_group)) }

        it "has layer_read permission" do
          expect(role.permissions).to include(:layer_read)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_group))
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:toppers) }

          it "may get people" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not get visible people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "bottom group" do
          let(:group) { groups(:bottom_group_one_one) }

          it "may not get non-visible" do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_and_below_full do
        let(:role) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer)) }

        it "has group_and_below_full permission" do
          expect(role.permissions).to include(:group_and_below_full)
        end

        context "in own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer))
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:top_layer))
            is_expected.to include(other.person)
          end
        end

        context "in below group" do
          let(:group) { groups(:top_group) }

          it "may get people" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "in below layer" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not get people" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_and_below_read do
        let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

        it "has group_and_below_read permission" do
          expect(role.permissions).to include(:group_and_below_read)
        end

        context "in own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "in below group" do
          let(:group) { Fabricate(Group::GlobalGroup.name, parent: role.group) }

          it "may get people" do
            other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "in same layer" do
          let(:group) { groups(:toppers) }

          it "may not get people" do
            other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_full do
        let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

        it "has group_full permission" do
          expect(role.permissions).to include(:group_full)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: groups(:bottom_group_one_one))
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:bottom_group_one_two) }

          it "may not get people" do
            other = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :contact_data do
        let(:role) { Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers)) }

        it "has contact data permission" do
          expect(role.permissions).to include(:contact_data)
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::GlobalGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:top_group) }

          it "may get people with contact data" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may get people with contact data" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may not get people without contact data" do
            other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :group_read do
        let(:role) { Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers)) }

        it "has only login permission" do
          expect(role.permissions).to eq([:group_read])
        end

        context "own group" do
          let(:group) { role.group }

          it "may get himself" do
            is_expected.to include(role.person)
          end

          it "may get people in his group" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:top_group) }

          it "may not get people with contact data" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not get people with contact data" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      describe "no permissions" do
        let(:role) { Fabricate(Role::External.name.to_sym, group: groups(:top_group)) }

        it "has no permissions" do
          expect(role.permissions).to eq([])
        end

        context "own group" do
          let(:group) { role.group }

          if action == :index
            it "may not get himself" do
              is_expected.not_to include(role.person)
            end
          else
            it "may get himself" do
              is_expected.to include(role.person)
            end
          end

          it "may not get people in his group" do
            other = Fabricate(Group::TopGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end

          it "may not get external people in his group" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "group in same layer" do
          let(:group) { groups(:toppers) }

          it "may not get people with contact data" do
            other = Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end

        context "lower group" do
          let(:group) { groups(:bottom_layer_one) }

          it "may not get people with contact data" do
            other = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group)
            is_expected.not_to include(other.person)
          end
        end
      end

      context :root do
        let(:user) { people(:root) }

        context "every group" do
          let(:group) { groups(:top_group) }

          it "may get all people" do
            other = Fabricate(Group::TopGroup::Member.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "may get external people" do
            other = Fabricate(Role::External.name.to_sym, group: group)
            is_expected.to include(other.person)
          end

          it "does join roles so table displays based of roles work" do
            expect { subject.where(roles: {type: ""}) }.not_to raise_error
          end
        end

        if action == :global
          it "may get herself" do
            is_expected.to include(user)
          end

          it "may get people outside groups" do
            other = Fabricate(:person)
            is_expected.to include(other)
          end
        end
      end
    end
  end

  describe "layer_and_below_read_details" do
    let(:user) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: groups(:top_group)).person.reload }

    before do
      allow(Group::TopGroup::LocalSecretary).to receive(:permissions)
        .and_return([:layer_and_below_read_details])
    end

    shared_examples "lists people only up to details" do
      it "lists people in group list" do
        expect(Person.accessible_by(PersonReadables.new(user, group))).to include(other)
      end

      it "lists people in global and details lists" do
        expect(Person.accessible_by(PersonReadables.new(user))).to include(other)
        expect(Person.accessible_by(PersonDetailsReadables.new(user))).to include(other)
      end

      it "does not list people in full lists" do
        expect(Person.accessible_by(PersonFullReadables.new(user, group))).not_to include(other)
        expect(Person.accessible_by(PersonFullReadables.new(user))).not_to include(other)
      end
    end

    context "in same layer" do
      let(:group) { groups(:toppers) }
      let(:other) { Fabricate(Group::GlobalGroup::Member.name.to_sym, group: group).person }

      it_behaves_like "lists people only up to details"

      context "with people invisible from above" do
        let(:other) { Fabricate(Role::External.name.to_sym, group: group).person }

        it_behaves_like "lists people only up to details"
      end
    end

    context "in layer below" do
      let(:group) { groups(:bottom_layer_one) }
      let(:other) { Fabricate(Group::BottomLayer::Member.name.to_sym, group: group).person }

      it_behaves_like "lists people only up to details"

      it "does not list people invisible from above" do
        invisible = Fabricate(Role::External.name.to_sym, group: group).person
        expect(Person.accessible_by(PersonReadables.new(user, group))).not_to include(invisible)
        expect(Person.accessible_by(PersonReadables.new(user))).not_to include(invisible)
      end
    end
  end

  describe "group_read_contact_data" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:user) { Fabricate(Group::BottomGroup::NoPermissions.name.to_sym, group: group).person.reload }
    let(:other) { Fabricate(Role::External.name.to_sym, group: group).person }

    before do
      allow(Group::BottomGroup::NoPermissions).to receive(:permissions)
        .and_return([:group_read_contact_data])
    end

    it "lists people of same group in group list" do
      expect(Person.accessible_by(PersonReadables.new(user, group))).to include(other)
    end

    it "lists people of same group but no others in global list" do
      accessibles = Person.accessible_by(PersonReadables.new(user))
      expect(accessibles).to include(other)
      expect(accessibles).not_to include(people(:bottom_member))
    end

    it "does not list people of same group in full and details lists" do
      expect(Person.accessible_by(PersonFullReadables.new(user))).not_to include(other)
      expect(Person.accessible_by(PersonDetailsReadables.new(user))).not_to include(other)
    end
  end
end
