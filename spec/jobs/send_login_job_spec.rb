# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationConfirmationJob do

  let(:sender) { people(:top_leader) }
  let(:recipient) { people(:bottom_member) }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  subject { SendLoginJob.new(recipient, sender) }

  it 'generates reset token' do
    recipient.reset_password_token.should be_nil
    subject.perform
    recipient.reload.reset_password_token.should be_present
  end

  it 'sends email' do
    subject.perform
    last_email.should be_present
    last_email.body.should_not =~ /#{recipient.reload.reset_password_token}/
  end

  its(:parameters) { should == { recipient_id: recipient.id, sender_id: sender.id } }
end
