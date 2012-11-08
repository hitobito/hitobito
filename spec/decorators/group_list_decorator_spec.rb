require 'spec_helper'

describe GroupListDecorator do
  
  subject { GroupListDecorator.new(groups(:top_layer)) } 

  its(:sub) { should =~ [groups(:top_group)] }
  its(:label_sub) { should eq 'Untergruppen' } 

  context "layer" do
    subject { GroupListDecorator.new(groups(:top_layer)).layer } 

    its(:keys) { should eq ['Gruppen'] } 
    its(:values) { should =~ [[groups(:bottom_layer_one), groups(:bottom_layer_two)]]  }
  end

end
