# encoding: utf-8

require 'spec_helper'

describe Event::RegisterMailer do
  
  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end
  
  let(:group) { event.groups.first }
  let(:event) { events(:top_event) }
  
  let(:person) { Fabricate(:person, email: 'fooo@example.com', reset_password_token: 'abc') }
  let(:mail) { Event::RegisterMailer.register_login(person, group, event) }
  
  context "headers" do
    subject { mail }
    its(:subject) { should eq "Anmeldelink für Jubla Anlass" }
    its(:to)      { should eq(["fooo@example.com"]) }
    its(:from)    { should eq(["noreply@jubla.ch"]) }
  end 

  context "body" do
    subject { mail.body }
    
    it "renders placeholders" do
      should =~ /Top Event/
      should =~ /#{person.first_name}/
    end
    
    it "renders link" do
      should =~ /<a href="http:\/\/test.host\/groups\/#{group.id}\/events\/#{event.id}\?onetime_token=#{person.reset_password_token}">/
    end
  end
end
