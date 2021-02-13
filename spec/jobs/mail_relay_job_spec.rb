# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailRelayJob do
  subject { MailRelayJob.new }

  it "relays mails and gets rescheduled" do
    Settings.email.retriever.config = Config::Options.new(address: "localhost")
    expect(MailRelay::Lists).to receive(:relay_current)
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  its(:parameters) { should be_blank }
end
