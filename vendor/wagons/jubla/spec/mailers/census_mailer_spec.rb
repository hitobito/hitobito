# encoding: UTF-8
require "spec_helper"

describe CensusMailer do
  let(:person) { people(:top_leader) }
  let(:census) { censuses(:two_o_12) }
  
  subject { mail }
  
  describe "#invitation" do 
    let(:mail) { CensusMailer.invitation(census, ['test@example.com', 'test2@example.com']) }
    
    its(:subject) { should == "Bestandesmeldung ausfüllen" }
    its(:to)      { should == ['jubla@puzzle.ch'] }
    its(:bcc)     { should == ['test@example.com', 'test2@example.com'] }
    its(:from)    { should == ["jubla+noreply@puzzle.ch"] }
    its(:body)    { should =~ /bis am 31\.10\.2012/ }
  end
  
    
  describe "#reminder" do 
    let(:mail) { CensusMailer.reminder(people(:top_leader).email, census, ['test@example.com', 'test2@example.com']) }
    
    its(:subject) { should == "Bestandesmeldung ausfüllen" }
    its(:to)      { should == ['test@example.com', 'test2@example.com'] }
    its(:from)    { should == [people(:top_leader).email] }
    its(:body)    { should =~ /bis am 31\.10\.2012/ }
  end
end