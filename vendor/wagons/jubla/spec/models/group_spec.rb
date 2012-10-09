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
    it { should have(2).role_types }
    it { should be_layer }
    
    its(:possible_children) { should include(Group::SimpleGroup) }
  end
  
  describe Group::Flock do
    subject { Group::Flock }

    it { should have(2).possible_children }
    it { should have(0).default_children }
    it { should have(7).role_types }
    it { should be_layer }
  end
  
  describe Group::SimpleGroup do
    subject { Group::SimpleGroup }
    
    it { should have(1).possible_children }
    it { should have(0).default_children }
    it { should have(4).role_types }
    it { should_not be_layer }
    its(:possible_children) { should include(Group::SimpleGroup) }
    
    it "includes the common roles" do
      subject.role_types.should include(Jubla::Role::GroupAdmin)
    end
    
    it "includes the external role" do
      subject.role_types.should include(Jubla::Role::External)
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

  describe ".can_offer_courses" do 
    subject { Group.can_offer_courses }

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
      expected = ["Jubla Schweiz", "Kanton Bern", "Nordostschweiz", "Thun", "Ausserroden", 
                  "Innerroden", "Bern", "Muri"]
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

      # TODO - pz should this not read 
      # group.possible_children.should include(*group.default_children)
      # instead?
      #
      it "default_children must be part of possible_children" do
        group.default_children.should include(*group.default_children)
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
