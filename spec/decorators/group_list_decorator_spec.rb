require 'spec_helper'

describe GroupListDecorator do
  
  subject { GroupListDecorator.new(groups(:top_layer)) } 
  its(:layer) { should =~ [groups(:bottom_layer_one), groups(:bottom_layer_two)] }
  its(:sub) { should =~ [groups(:top_group)] }
  its(:label_layer) { should eq 'Gruppen' } 
  its(:label_sub) { should eq 'Untergruppen' } 
end
