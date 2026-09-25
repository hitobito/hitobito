# frozen_string_literal: true

#  Copyright (c) 2018-2026, Grünliberale Partei Schweiz. This file is part of
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

  it "creates log entry when sync result is partial" do
    freeze_time

    partial_result = Synchronize::Mailchimp::Result.new
    partial_result.track(:unsubscribe_members, %w[ok@example.com bounced@example.com], {
      total_operations: 2,
      finished_operations: 2,
      errored_operations: 1,
      operation_results: [
        {title: nil, detail: nil, status: 204, operation_id: "ok@example.com"},
        {title: "Method Not Allowed",
         detail: "Can not archive a contact that is bounced, pending or archived.",
         status: 405,
         operation_id: "bounced@example.com"}
      ]
    })
    allow_any_instance_of(Synchronize::Mailchimp::Synchronizator).to receive(:perform)
    allow_any_instance_of(Synchronize::Mailchimp::Synchronizator).to receive(:result).and_return(partial_result)

    expect do
      enqueue_and_run_job(subject)
    end.to change { HitobitoLogEntry.count }.by(1)

    mailing_list.reload

    check_mailing_list_status_and_partial_logging

    log = HitobitoLogEntry.last

    operation_results = JSON.parse(log.payload).deep_symbolize_keys
      .dig(:data, :unsubscribe_members, :partial, 3)
    expect(operation_results).to include(
      hash_including(operation_id: "bounced@example.com", status: 405)
    )
  end

  it "creates log entry when sync result is failed without raising" do
    freeze_time

    failed_result = Synchronize::Mailchimp::Result.new
    failed_result.exception =
      Synchronize::Mailchimp::Client::Error.new("Batch nbs4yj8qzb exeeded max_attempts, status: finalizing")
    allow_any_instance_of(Synchronize::Mailchimp::Synchronizator).to receive(:perform)
    allow_any_instance_of(Synchronize::Mailchimp::Synchronizator).to receive(:result).and_return(failed_result)

    expect do
      enqueue_and_run_job(subject)
    end.to change { HitobitoLogEntry.count }.by(1)

    mailing_list.reload

    check_mailing_list_status_and_error_logging_on_failure(
      exception: "Synchronize::Mailchimp::Client::Error - Batch nbs4yj8qzb exeeded max_attempts, status: finalizing"
    )
  end

  context "with an invalid mailing list" do
    before do
      mailing_list.update_column(:mailchimp_api_key, "invalid_key_format")
      expect(mailing_list.reload).not_to be_valid
    end

    it "still sets mailing_list state to syncing when enqueuing" do
      expect { subject.enqueue! }.not_to raise_error

      mailing_list.reload

      expect(mailing_list.mailchimp_syncing).to be true
    end

    it "still sets syncing to false after success" do
      freeze_time

      expect(subject).to receive(:perform)

      expect { enqueue_and_run_job(subject) }.not_to raise_error
      mailing_list.reload

      check_mailing_list_status_on_success
    end

    it "still sets syncing to false and creates log entry when job throws" do
      freeze_time

      expect(subject).to receive(:perform).and_throw(Exception)

      expect do
        enqueue_and_run_job(subject)
      end.to change { HitobitoLogEntry.count }.by(1)

      mailing_list.reload

      check_mailing_list_status_and_error_logging_on_failure
    end
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

    it "should set mailchimp state to syncing and create job observation" do
      expect do
        subject.enqueue!
      end.to change { Delayed::Job.count }.by 1

      mailing_list.reload

      expect(subject.job_observation).not_to be_nil
      expect(mailing_list.mailchimp_syncing).to be true
    end

    it "should set correct mailing list status and report success" do
      freeze_time

      mailchimp_sync_delayed_job = subject.enqueue!

      expect(subject).to receive(:perform)
      expect(subject.job_observation).to receive(:report_success!).with(1).and_call_original

      run_enqueued_job(mailchimp_sync_delayed_job)
      mailing_list.reload

      check_mailing_list_status_on_success
    end

    it "should set correct mailing list status and and report failure" do
      freeze_time

      mailchimp_sync_delayed_job = subject.enqueue!

      expect(subject).to receive(:perform).and_throw(Exception).twice
      expect(subject.job_observation).to receive(:report_failure!).and_call_original

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

  def check_mailing_list_status_and_partial_logging
    log = HitobitoLogEntry.last

    expect(log).to have_attributes({
      subject: mailing_list,
      category: "mail",
      message: "Mailchimp Abgleich war teilweise nicht erfolgreich"
    })

    expect(mailing_list).to have_attributes({
      mailchimp_syncing: false,
      mailchimp_last_synced_at: Time.current
    })
  end

  def check_mailing_list_status_and_error_logging_on_failure(
    exception: "UncaughtThrowError - uncaught throw Exception"
  )
    log = HitobitoLogEntry.last

    expect(log).to have_attributes({
      subject: mailing_list,
      category: "mail",
      message: "Mailchimp Abgleich war nicht erfolgreich"
    })

    expect(JSON.parse(log.payload).deep_symbolize_keys).to eq({data: {exception: exception}})

    expect(mailing_list).to have_attributes({
      mailchimp_syncing: false,
      mailchimp_last_synced_at: nil,
      mailchimp_result: have_attributes(state: :failed)
    })
  end
end
