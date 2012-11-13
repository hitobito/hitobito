require 'spec_helper'

describe CensusReminderJob do
  
  let(:flock) { groups(:bern) }
  subject { CensusReminderJob.new(people(:top_leader), Census.current, flock) } 
  
  
  describe "#recipients" do
    it "contains all flock leaders" do
      all = []
      all << Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person.email
      all << Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person.email
      
      # empty email
      Fabricate(Group::Flock::Leader.name.to_sym, group: flock, person: Fabricate(:person, email: ''))
      # different roles
      Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)).person.email
      Fabricate(Group::ChildGroup::Leader.name.to_sym, group: groups(:asterix)).person.email
      Fabricate(Group::Flock::Guide.name.to_sym, group: flock)
      
      subject.recipients.should =~ all
    end
  end
  
  describe "#perform" do
    it "sends email if flock has leaders" do
      Fabricate(Group::Flock::Leader.name.to_sym, group: flock)
      Fabricate(Group::Flock::Leader.name.to_sym, group: flock)
      
      expect { subject.perform }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
    
    it "does not send email if flock has no leaders" do
      expect { subject.perform }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end
  
end
