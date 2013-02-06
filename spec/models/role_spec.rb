# == Schema Information
#
# Table name: roles
#
#  id                 :integer          not null, primary key
#  person_id          :integer          not null
#  group_id           :integer          not null
#  type               :string(255)      not null
#  label              :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deleted_at         :datetime
#  employment_percent :integer
#  honorary           :boolean
#

require 'spec_helper'

describe Role do

  context "class" do
    subject { Role }

    its(:all_types) { should have(9).items }

    its(:visible_types) { should have(7).items }

    its(:visible_types) { should_not include(Group::BottomGroup::Member) }

    it "should have two types with permission :layer_full" do
      Role.types_with_permission(:layer_full).to_set.should == [Group::TopGroup::Leader, Group::BottomLayer::Leader].to_set
    end

    it "should have no types with permission :not_existing" do
      Role.types_with_permission(:not_existing).should be_empty
    end
  end

  context "regular" do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bottom_layer_one) }
    subject do
      r = Role.new
      r.person = person
      r.group = group
      r
    end

    context "type" do
      it "is invalid without type" do
        should have(1).errors_on(:type)
      end
  
      it "is invalid with non-existing type" do
        subject.type = "Foo"
        should have(1).errors_on(:type)
      end
      
      it "is invalid with type from other group" do
        subject.type = "Group::TopGroup::Leader"
        should have(1).errors_on(:type)
      end
  
      it "is valid with allowed type" do
        subject.type = "Group::BottomLayer::Leader"
        should be_valid
      end
    end
    
    context "primary group" do
      before { subject.type = "Group::BottomLayer::Leader" }
      
      it "is set for first role" do
        subject.save.should be_true
        person.primary_group_id.should == group.id
      end
      
      it "is not set on subsequent roles" do
        Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
        subject.save
        person.primary_group_id.should_not == group.id
      end
      
      it "is reset if role is destroyed" do
        subject.save
        subject.destroy.should be_true
        person.primary_group_id.should be_nil
      end
      
      it "is not reset if role is destroyed and other roles in the same group exist" do
        Fabricate(Group::BottomLayer::Member.name.to_s, person: person, group: group)
        subject.save
        subject.destroy.should be_true
        person.primary_group_id.should == group.id
      end
      
      it "is not reset if role is destroyed and primary group is another group" do
        subject.save
        person.update_column :primary_group_id, 42
        subject.destroy.should be_true
        person.primary_group_id.should == 42
      end
    end
    
    context "contact data callback" do
      
      it "sets contact data flag on person" do
        subject.type = "Group::BottomLayer::Leader"
        subject.save!
        person.should be_contact_data_visible
      end
      
      it "sets contact data flag on person with flag" do
        person.update_attribute :contact_data_visible, true
        subject.type = "Group::BottomLayer::Leader"
        subject.save!
        person.should be_contact_data_visible
      end
      
      it "removes contact data flag on person " do
        person.update_attribute :contact_data_visible, true
        subject.type = "Group::BottomLayer::Leader"
        subject.save!
        
        role = Role.find(subject.id)  # reload from db to get the correct class
        role.destroy
        
        person.reload.should_not be_contact_data_visible
      end
           
      it "does not remove contact data flag on person when other roles exist" do
        Fabricate(Group::TopGroup::Member.name.to_s, group: groups(:top_group), person: person)
        subject.type = "Group::BottomLayer::Leader"
        subject.save!
        
        role = Role.find(subject.id)  # reload from db to get the correct class
        role.destroy
        
        person.reload.should be_contact_data_visible
      end
    end
  end
  
  describe ".normalize_label" do
    it "reuses existing label" do
      a1 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'Foo', group: groups(:bottom_layer_one))
      a2 = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'fOO', group: groups(:bottom_layer_one))
      a2.label.should == 'Foo'
    end
  end
  
  describe "#available_labels" do
    subject { Group::BottomLayer::Leader.available_labels }
    
    it "includes labels from database" do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'Foo', group: groups(:bottom_layer_one))
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'FOo', group: groups(:bottom_layer_one))
      should == ['Foo']
    end
        
    it "includes labels from this type only" do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'Foo', group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Member.name.to_s, label: 'Bar', group: groups(:bottom_layer_one))
      should == ['Foo']
    end
  end

  context "#destroy" do
    it "deleted young roles from database" do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'Foo', group: groups(:bottom_layer_one))
      a.destroy
      Role.with_deleted.where(id: a.id).should_not be_exists
    end
    
    it "flags old roles" do
      a = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'Foo', group: groups(:bottom_layer_one))
      a.created_at = Time.zone.now - Settings.role.minimum_days_to_archive.days - 1
      a.destroy
      Role.only_deleted.find(a.id).should be_present
    end
  end

end
