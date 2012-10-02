require 'spec_helper'

describe ActiveModel::Name do
  
  
  it "has regular route keys" do
    Event.model_name.route_key == 'events'
  end
  
  it "has route keys from sti base class" do
    Group::TopLayer.model_name.route_key.should == 'groups'
  end
  it "does not have demodulized route keys by default" do
    Event::Kind.model_name.route_key.should == 'event_kinds'
  end
  
  it "has demodulized route keys if requested" do
    Event::Application.model_name.route_key.should == 'applications'
  end
end


