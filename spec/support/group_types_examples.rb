
# A set of examples that validate the group hierarchy and role definitions as well as the group fixtures.

shared_examples 'group types' do |options|

  describe 'fixtures' do
    it 'is a valid nested set' do
      begin
        Group.should be_left_and_rights_valid
        Group.should be_no_duplicates_for_columns
        Group.should be_all_roots_valid
        Group.should be_valid
      rescue => e
        puts e
        Group.rebuild!
        puts 'valid are:'
        Group.order(:lft).each do |g|
          puts '  ' * g.level + "#{g.name} lft: #{g.lft}, rgt: #{g.rgt}"
        end
      end
    end

    it 'has all layer_group_ids set correctly' do
      Group.all.each do |group|
        msg = "#{group.to_s}: expected <#{group.layer_group.id}> (#{group.layer_group.to_s}), "
        msg << "got <#{group.layer_group_id}> (#{Group.find(group.layer_group_id).to_s})"
        group.layer_group_id.should(eq(group.layer_group.id), msg)
      end
    end
  end

  describe '#all_types' do
    subject { Group.all_types }

    it 'must have root as the first item' do
      subject.first.should == Group.root_types.first
    end
  end

  Group.all_types.each do |group|
    context group do

      it 'default_children must be part of possible_children' do
        group.possible_children.should include(*group.default_children)
      end

      it 'has an own label' do
        group.label.should_not eq(Group.label)
      end

      unless group.layer?
        it 'only layer groups may contain layer children' do
          group.possible_children.select(&:layer).should be_empty
        end
      end

      group.role_types.each do |role|
        context role do
          it 'must have valid permissions' do
            # although it looks like, this example is about role.permissions and not about Role::Permissions
            Role::Permissions.should include(*role.permissions)
          end

          it 'has an own label' do
            role.label.should_not eq(Role.label)
          end
        end
      end
    end
  end
end
