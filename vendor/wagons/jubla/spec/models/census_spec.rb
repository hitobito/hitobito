require 'spec_helper'

describe Census do
  
  describe '.last' do
    subject { Census.last }
    
    it { should == censuses(:two_o_12) }
  end
  
  describe '.current' do
    subject { Census.current }
    
    it { should == censuses(:two_o_12) }
  end
end
