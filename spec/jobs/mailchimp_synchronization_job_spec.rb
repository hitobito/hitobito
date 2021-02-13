# encoding: utf-8

#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailchimpSynchronizationJob do

  let(:group) { groups(:top_group) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group, mailchimp_api_key: "1234") }

  subject { MailchimpSynchronizationJob.new(mailing_list.id) }

  it "sets mailing_list state to syncing if jobs eunqueues" do
    expect do
      subject.enqueue!
    end.to change { Delayed::Job.count }.by 1

    mailing_list.reload

    expect(mailing_list.mailchimp_syncing).to be true
  end

  it "it sets syncing to false after success" do
    time_now = Time.zone.now
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return(time_now)
    expect_any_instance_of(MailchimpSynchronizationJob).to receive(:perform)

    subject.enqueue!

    Delayed::Worker.new.work_off
    mailing_list.reload

    expect(mailing_list.mailchimp_syncing).to be false
    expect(mailing_list.mailchimp_last_synced_at.to_i).to eq(time_now.to_i)
    expect(mailing_list.mailchimp_result.state).to eq :unchanged
  end

  it "it sets syncing to false after success" do
    time_now = Time.zone.now
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return(time_now)
    expect_any_instance_of(MailchimpSynchronizationJob).to receive(:perform).and_throw(Exception)

    subject.enqueue!

    Delayed::Worker.new.work_off
    mailing_list.reload

    expect(mailing_list.mailchimp_syncing).to be false
    expect(mailing_list.mailchimp_last_synced_at).to be_nil
    expect(mailing_list.mailchimp_result.state).to eq :failed
  end

  describe "setting" do
    it "syncs per default" do
      expect_any_instance_of(Synchronize::Mailchimp::Synchronizator).to receive(:perform)
      subject.enqueue!
      Delayed::Worker.new.work_off
    end

    it "may be overridden via setting" do
      expect(Settings.mailchimp).to receive(:enabled).and_return(false)
      expect_any_instance_of(Synchronize::Mailchimp::Synchronizator).not_to receive(:perform)
      subject.enqueue!
      Delayed::Worker.new.work_off
    end
  end
end
