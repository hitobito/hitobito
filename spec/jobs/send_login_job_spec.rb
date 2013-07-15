# encoding: utf-8
require 'spec_helper'

describe Event::ParticipationConfirmationJob do

  let(:sender) { people(:top_leader) }
  let(:recipient) { people(:bottom_member) }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  subject { SendLoginJob.new(recipient, sender) }

  it "generates reset token" do
    recipient.reset_password_token.should be_nil
    subject.perform
    recipient.reload.reset_password_token.should be_present
  end

  it "sends email" do
    subject.perform
    last_email.should be_present
    last_email.body.should =~ /#{recipient.reload.reset_password_token}/
  end

  its(:parameters) { should == {recipient_id: recipient.id, sender_id: sender.id} }
end