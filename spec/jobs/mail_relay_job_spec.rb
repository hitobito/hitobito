require 'spec_helper'

describe MailRelayJob do
  
  subject { MailRelayJob.new }
  
  it "relays mails and gets rescheduled" do
    MailRelay::Lists.should_receive(:relay_current)
    subject.perform
    subject.delayed_jobs.should be_exists
  end
end
