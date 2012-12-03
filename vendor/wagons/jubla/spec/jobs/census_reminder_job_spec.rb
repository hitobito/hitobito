require 'spec_helper'

describe CensusReminderJob do
  
  let(:flock) { groups(:bern) }
  let(:leaders) do
    all = []
    all << Fabricate(Group::Flock::Leader.name.to_sym, group: flock, person: Fabricate(:person, email: 'test1@example.com')).person
    all << Fabricate(Group::Flock::Leader.name.to_sym, group: flock, person: Fabricate(:person, email: 'test2@example.com')).person
    
    # empty email
    all << Fabricate(Group::Flock::Leader.name.to_sym, group: flock, person: Fabricate(:person, email: '')).person
    all
  end
  
  subject { CensusReminderJob.new(people(:top_leader), Census.current, flock) } 
  
  
  describe "#recipients" do
    
    it "contains all flock leaders" do
      leaders
      
      # different roles
      Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)).person.email
      Fabricate(Group::ChildGroup::Leader.name.to_sym, group: groups(:asterix)).person.email
      Fabricate(Group::Flock::Guide.name.to_sym, group: flock)
      
      subject.recipients.should =~ leaders
    end
  end
  
  describe "#perform" do
    it "sends email if flock has leaders" do
      leaders
      expect { subject.perform }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
    
    it "does not send email if flock has no leaders" do
      expect { subject.perform }.not_to change { ActionMailer::Base.deliveries.size }
    end
    
    it "finds ast address" do
      leaders
      subject.perform
      last_email.body.should =~ /AST<br\/>3000 Bern/
    end
    
    it "sends only to leaders with email" do
      leaders
      subject.perform
      last_email.to.should == [leaders.first.email, leaders.second.email]
    end
  end
  
end
