require 'spec_helper'

describe FilterNavigation::People, type: :model do
    
  let(:template) do
    double('template').tap do |t|
      t.stub(can?: true)
      t.stub(group_people_path: 'people_path')
      t.stub(group_people_filter_path: 'people_filter_path')
      t.stub(new_group_people_filter_path: 'new_people_filter_path')
      t.stub(link_to: '<a>')
      t.stub(link_action_destroy: '<a>')
      t.stub(icon: '<i>')
      t.stub(ti: 'delete')
      t.stub(content_tag: '<content>')
    end
  end
  
  let(:group) { groups(:top_layer) }
  
  let(:role_types) { [Group::TopGroup::Leader.sti_name, 
                      Group::BottomLayer::Leader.sti_name] }
                        
  context "without params" do
    subject { FilterNavigation::People.new(template, group, nil, nil, nil)}
    
    its(:main_items)      { should have(2).items }
    its(:active_label)    { should == 'Mitglieder' }
    its('dropdown.active') { should be_false }
    its('dropdown.label')  { should == 'Weitere Ansichten' }
    its('dropdown.items')  { should have(1).item }
    
    context "with custom filters" do
      
      before do
        group.people_filters.create!(name: 'Leaders', 
                                     kind: 'deep', 
                                     role_types: role_types)
      end
          
      its('dropdown.active') { should be_false }
      its('dropdown.label')  { should == 'Weitere Ansichten' }
      its('dropdown.items')  { should have(3).items }
      
    end
  end
  
  context "with selected filter" do
    
    before do
      group.people_filters.create!(name: 'Leaders', 
                                   kind: 'deep', 
                                   role_types: role_types)
    end
      
    subject { FilterNavigation::People.new(template, group, 'Leaders', role_types, nil)}
    
    its(:main_items)      { should have(2).items }
    its(:active_label)    { should == nil }
    its('dropdown.active') { should be_true }
    its('dropdown.label')  { should == 'Leaders' }
    its('dropdown.items')  { should have(3).item }
  end
end
