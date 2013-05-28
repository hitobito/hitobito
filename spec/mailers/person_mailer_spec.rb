# encoding: UTF-8
require "spec_helper"

describe Event::ParticipationMailer do

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  let(:sender) { people(:top_leader) }
  let(:recipient) { people(:bottom_member) }
  let(:mail) { PersonMailer.login(recipient, sender) }

  subject { mail }

  its(:to)      { should == [recipient.email] }
  its(:reply_to)    { should == [sender.email] }
  its(:subject) { should == 'Willkommen bei hito.bito' }
  its(:body)    { should =~ /Hallo Bottom<br\/>/}

end
