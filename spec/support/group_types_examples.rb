#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A set of examples that validate the group hierarchy and role definitions as well as the group fixtures.
shared_examples "group types" do |options|
  describe "fixtures" do
    it "is a valid nested set" do
      expect(Group).to be_left_and_rights_valid
      expect(Group).to be_no_duplicates_for_columns
      expect(Group).to be_all_roots_valid
      expect(Group).to be_valid
    rescue => e
      puts e
      Group.rebuild!
      puts "valid are:"
      Group.order(:lft).each do |g|
        puts "  " * g.level + "#{g.name} lft: #{g.lft}, rgt: #{g.rgt}"
      end
    end

    it "has all layer_group_ids set correctly" do
      Group.all.each do |group|
        msg = "#{group}: expected <#{group.layer_group.id}> (#{group.layer_group}), "
        msg << "got <#{group.layer_group_id}> (#{Group.find(group.layer_group_id)})"
        expect(group.layer_group_id).to(eq(group.layer_group.id), msg)
      end
    end
  end

  describe "#all_types" do
    subject { Group.all_types }

    it "must have root as the first item" do
      expect(subject.first).to eq(Group.root_types.first)
    end
  end

  Group.all_types.each do |group|
    context group do
      it "default_children must be part of possible_children" do
        expect(group.possible_children).to include(*group.default_children)
      end

      it "has an own label" do
        expect(group.label).not_to eq(Group.label)
      end

      unless group.layer?
        it "only layer groups may contain layer children" do
          expect(group.possible_children.select(&:layer)).to be_empty
        end
      end

      group.role_types.each do |role|
        context role do
          it "must have valid permissions" do
            # although it looks like, this example is about role.permissions and not about Role::Permissions
            expect(Role::Permissions).to include(*role.permissions)
          end

          it "must have valid kind" do
            # although it looks like, this example is about role.permissions and not about Role::Permissions
            expect(Role::Kinds + [nil]).to include(role.kind)
          end

          it "has an own label" do
            expect(role.label).not_to eq(Role.label)
          end
        end
      end
    end
  end
end
