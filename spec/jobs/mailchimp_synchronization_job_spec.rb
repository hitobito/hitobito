# frozen_string_literal: true

#  Copyright (c) 2018-2023, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailchimpSynchronizationJob do
  include DelayedJobSpecHelper

  let(:group) { groups(:top_group) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group, mailchimp_api_key: "abc-us1") }

  subject { MailchimpSynchronizationJob.new(mailing_list.id) }

  before do
    mailing_list.update!(mailchimp_api_key: "abc-us1", mailchimp_list_id: "1")
  end

  it "sets mailing_list state to syncing if jobs enqueues" do
    expect do
      subject.enqueue!
    end.to change { Delayed::Job.count }.by 1

    mailing_list.reload

    expect(mailing_list.mailchimp_syncing).to be true
  end

  it "sets syncing to false after success" do
    freeze_time

    expect(subject).to receive(:perform)

    enqueue_and_run_job(subject)
    mailing_list.reload

    check_mailing_list_status_on_success
  end

  it "sets syncing to false and creates log entry when job throws" do
    freeze_time

    expect(subject).to receive(:perform).and_throw(Exception)

    expect do
      enqueue_and_run_job(subject)
    end.to change { HitobitoLogEntry.count }.by(1)

    mailing_list.reload

    check_mailing_list_status_and_error_logging_on_failure
  end

  it "noops if not a mailchimp list" do
    subject.enqueue!

    mailing_list.update!(mailchimp_api_key: nil)
    expect_any_instance_of(Synchronize::Mailchimp::Synchronizator).not_to receive(:perform)
    Delayed::Worker.new.work_off
    expect(mailing_list.mailchimp_syncing).to be false
  end

  describe "initiated by user" do
    before do
      allow(Auth).to receive(:current_person).and_return(people(:top_leader))
    end

    it "should set mailchimp state to syncing and create user job result" do
      expect do
        subject.enqueue!
      end.to change { Delayed::Job.count }.by 1

      mailing_list.reload

      expect(subject.user_job_result).not_to be_nil
      expect(mailing_list.mailchimp_syncing).to be true
    end

    it "should set correct mailing list status and report success" do
      freeze_time

      mailchimp_sync_delayed_job = subject.enqueue!

      expect(subject).to receive(:perform)
      expect(subject.user_job_result).to receive(:report_success!).with(1).and_call_original

      run_enqueued_job(mailchimp_sync_delayed_job)
      mailing_list.reload

      check_mailing_list_status_on_success
    end

    it "should set correct mailing list status and and report failure" do
      freeze_time

      mailchimp_sync_delayed_job = subject.enqueue!

      expect(subject).to receive(:perform).and_throw(Exception).twice
      expect(subject.user_job_result).to receive(:report_failure!).and_call_original

      expect do
        2.times { run_enqueued_job(mailchimp_sync_delayed_job) }
      end.to change { HitobitoLogEntry.count }.by(2)

      mailing_list.reload

      check_mailing_list_status_and_error_logging_on_failure
    end
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

  private

  def check_mailing_list_status_on_success
    expect(mailing_list).to have_attributes({
      mailchimp_syncing: false,
      mailchimp_last_synced_at: Time.current,
      mailchimp_result: have_attributes(state: :unchanged)
    })
  end

  def check_mailing_list_status_and_error_logging_on_failure
    log = HitobitoLogEntry.last

    expect(log).to have_attributes({
      subject: mailing_list,
      category: "mail",
      message: "Mailchimp Abgleich war nicht erfolgreich"
    })

    expect(JSON.parse(log.payload).deep_symbolize_keys).to eq({
      data: {exception: "UncaughtThrowError - uncaught throw Exception"}
    })

    expect(mailing_list).to have_attributes({
      mailchimp_syncing: false,
      mailchimp_last_synced_at: nil,
      mailchimp_result: have_attributes(state: :failed)
    })
  end
end
