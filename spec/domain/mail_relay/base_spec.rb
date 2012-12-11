require 'spec_helper'

describe MailRelay::Base do
  
  let(:simple)  { Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'simple.eml'))) }
  let(:regular) { Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'regular.eml'))) }
  let(:list)    { Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'list.eml'))) }
  
  let(:relay) { MailRelay::Base.new(message) }
  
  describe "#envelope_receiver" do
    context "simple" do
      let(:message) { simple }
      
      it "returns nil" do
        relay.envelope_receiver.should be_nil
      end
    end
    
    context "regular" do
      let(:message) { regular }
      
      it "returns receiver" do
        relay.envelope_receiver.should == 'zumkehr@puzzle.ch'
      end
    end
    
    context "list" do
      let(:message) { list }
      
      it "returns receiver" do
        relay.envelope_receiver.should == 'zumkehr@puzzle.ch'
      end
    end
  end
  
  describe "#relay" do
    let(:message) { regular }
    
    subject { last_email }
    
    context "without receivers" do
      before { relay.relay }
      
      it { should be_nil }
    end
    
    context "with receivers" do
      let(:receivers) { %w(a@example.com b@example.com) } 
      before do
        relay.stub(:receivers).and_return(receivers)
        relay.relay
      end
      
      it { should be_present }
      its(:destinations) { should == receivers }
      its(:to) { should == ['zumkehr@puzzle.ch'] }
      its(:from) { should == ['animation@jublaluzern.ch'] }
    end
  end
end
