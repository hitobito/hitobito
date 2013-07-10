require 'spec_helper'

describe Group do

  describe 'fixtures' do
    it "is a valid nested set" do
      Group.should be_valid
    end

    it "has all layer_group_ids set correctly" do
      Group.all.each do |group|
        msg = "#{group.to_s}: expected <#{group.layer_group.id}> (#{group.layer_group.to_s}), "
        msg << "got <#{group.layer_group_id}> (#{Group.find(group.layer_group_id).to_s})"
        group.layer_group_id.should(eq(group.layer_group.id), msg)
      end
    end
  end

  describe Group::Federation do
    subject { Group::Federation }

    it { should have(6).possible_children }
    it { should have(2).default_children }
    it { should have(4).role_types }
    it { should be_layer }

    its(:possible_children) { should include(Group::SimpleGroup) }
  end

  describe Group::Flock do
    subject { Group::Flock }

    it { should have(2).possible_children }
    it { should have(0).default_children }
    it { should have(11).role_types }
    it { should be_layer }

    it "may have same name as other flock with different kind" do
      parent = groups(:city)
      flock = Group::Flock.new(name: 'bla', kind: 'Jungwacht')
      flock.parent = parent
      flock.save!
      other = Group::Flock.new(name: 'bla', kind: 'Blauring')
      other.parent = parent
      other.valid?
      other.errors.full_messages.should == []
    end

  end

  describe Group::SimpleGroup do
    subject { Group::SimpleGroup }
    it { should have(1).possible_children }
    it { should have(0).default_children }
    it { should have(6).role_types }
    it { should_not be_layer }
    its(:possible_children) { should include(Group::SimpleGroup) }

    it "includes the common roles" do
      subject.role_types.should include(Jubla::Role::GroupAdmin)
    end

    it "includes the external role" do
      subject.role_types.should include(Jubla::Role::External)
    end

    it "may have same name as other group with different parent" do
      flock = Group::SimpleGroup.new(name: 'bla')
      flock.parent = groups(:city)
      flock.save!
      other = Group::SimpleGroup.new(name: 'bla')
      other.parent = groups(:bern)
      other.should be_valid
    end

  end

  describe "#all_types" do
    subject { Group.all_types}

    it "must have root as the first item" do
      subject.first.should == Group::Federation
    end

    it "must have simple group as last item" do
      subject.last.should == Group::SimpleGroup
    end
  end

  describe ".course_offerers" do
    subject { Group.course_offerers }

    it "includes federation" do
      should include groups(:ch)
    end

    it "includes states" do
      should include groups(:be)
      should include groups(:no)
    end

    it "does not include flocks" do
      should_not include groups(:thun)
      should_not include groups(:ausserroden)
      should_not include groups(:innerroden)
      should_not include groups(:bern)
      should_not include groups(:muri)
    end

    it "orders by parent and name" do
      expected = ["Jubla Schweiz", "Kanton Bern", "Nordostschweiz"]
      subject.map(&:name).should eq expected
    end
  end


  def self.each_child(group)
    @processed ||= []
    @processed << group
    group.possible_children.each do |child|
      yield child unless @processed.include?(child)
    end
  end

  each_child(Group::Federation) do |group|
    context group do

      it "default_children must be part of possible_children" do
        group.possible_children.should include(*group.default_children)
      end

      unless group.layer?
        it "only layer groups may contain layer children" do
          group.possible_children.select(&:layer).should be_empty
        end
      end

      group.role_types.each do |role|
        context role do
          it "must have valid permissions" do
            # although it looks like, this example is about role.permissions and not about Role::Permissions
            Role::Permissions.should include(*role.permissions)
          end
        end
      end
    end
  end
end
