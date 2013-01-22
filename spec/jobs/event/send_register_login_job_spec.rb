# encoding: utf-8
require 'spec_helper'

describe Event::SendRegisterLoginJob do
  
  let(:group) { event.groups.first }
  let(:event) { events(:top_event) }
  
  let(:person) { Fabricate(:person) }
  
  subject { Event::SendRegisterLoginJob.new(person, group, event) }
  
  
  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end
  
  it "creates reset password token" do
    subject.perform
    person.reload.reset_password_token.should be_present
  end
  
  it "sends email" do
    subject.perform
    
    ActionMailer::Base.deliveries.should have(1).item
    last_email.subject.should == 'Anmeldelink für Jubla Anlass'
  end
  
end
