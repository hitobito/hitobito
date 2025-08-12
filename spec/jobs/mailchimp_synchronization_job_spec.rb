# frozen_string_literal: true

#  Copyright (c) 2018-2023, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailchimpSynchronizationJob do
  let(:group) { groups(:top_group) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group, mailchimp_api_key: "1234") }
  let(:now) { Time.zone.now }

  subject { MailchimpSynchronizationJob.new(mailing_list.id) }

  before do
    mailing_list.update!(mailchimp_api_key: "abc", mailchimp_list_id: "1")
  end

  it "sets mailing_list state to syncing if jobs eunqueues" do
    expect do
      subject.enqueue!
    end.to change { Delayed::Job.count }.by 1

    mailing_list.reload

    expect(mailing_list.mailchimp_syncing).to be true
  end

  it "sets syncing to false after success" do
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return(now)
    expect_any_instance_of(MailchimpSynchronizationJob).to receive(:perform)

    subject.enqueue!

    Delayed::Worker.new.work_off
    mailing_list.reload

    expect(mailing_list.mailchimp_syncing).to be false
    expect(mailing_list.mailchimp_last_synced_at.to_i).to eq(now.to_i)
    expect(mailing_list.mailchimp_result.state).to eq :unchanged
  end

  it "sets syncing to false and creates log entry when job throws" do
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return(now)
    expect_any_instance_of(MailchimpSynchronizationJob).to receive(:perform).and_throw(Exception)

    subject.enqueue!

    expect do
      Delayed::Worker.new.work_off
    end.to change { HitobitoLogEntry.count }.by(1)
    mailing_list.reload
    log = HitobitoLogEntry.last
    expect(log.subject).to eq mailing_list
    expect(log.category).to eq "mail"
    expect(log.message).to eq "Mailchimp Abgleich war nicht erfolgreich"

    expect(mailing_list.mailchimp_syncing).to be false
    expect(mailing_list.mailchimp_last_synced_at).to be_nil
    expect(mailing_list.mailchimp_result.state).to eq :failed
  end

  it "noops if not a mailchimp list" do
    subject.enqueue!

    mailing_list.update!(mailchimp_api_key: nil)
    expect_any_instance_of(Synchronize::Mailchimp::Synchronizator).not_to receive(:perform)
    Delayed::Worker.new.work_off
    expect(mailing_list.mailchimp_syncing).to be false
  end

  describe "setting" do
    it "syncs per default" do
      expect_any_instance_of(Synchronize::Mailchimp::Synchronizator).to receive(:perform)
      subject.enqueue!
      Delayed::Worker.new.work_off
    end

    it "may be overridden via setting" do
      expect(FeatureGate).to receive(:enabled?).with("mailchimp").and_return(false)
      expect_any_instance_of(Synchronize::Mailchimp::Synchronizator).not_to receive(:perform)
      subject.enqueue!
      Delayed::Worker.new.work_off
    end
  end
end
