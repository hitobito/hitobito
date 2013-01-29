require 'spec_helper'

describe PeopleFilterHelper do
  
  include StandardHelper
  include CrudHelper
  include LayoutHelper
  
  def can?(*args)
    true
  end
  
  
  context "#main_people_filter_links" do
    
    let(:group) { groups(:top_layer) }
    
    before do
      @group = group
    end
    
    subject { main_people_filter_links }
    
    it { should have(2).items }
    
  end
    
  context "#custom_people_filter_links" do
    
    let(:group) { groups(:top_layer) }
    
    before do
      group.people_filters.create!(name: 'Leaders', 
                                   kind: 'deep', 
                                   role_types: [Group::TopGroup::Leader.sti_name, 
                                                Group::BottomLayer::Leader.sti_name])
      @group = group
    end
    
    subject { custom_people_filter_links }
    
    it { should have(3).items }
    its([0]) { should be_kind_of(Hash) }
    
  end
end
