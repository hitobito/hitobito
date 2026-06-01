# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JobObservation do
  let(:person) { people(:top_leader) }
  let(:job_class) { "Export::ExampleExportJob" }
  let(:reports_progress) { false }
  let(:data) { SecureRandom.base64(128) }

  subject do
    Fabricate(:job_observation, job_class:, filetype: "csv", reports_progress:)
  end

  describe "default values", time_frozen: true do
    it "should set correct default values when values are not passed" do
      job_observation = JobObservation.create!(person:, job_class:)

      check_default_values(job_observation)
    end

    it "should set correct default values when values are passed as nil" do
      job_observation = JobObservation.create!(
        person:,
        job_class:,
        filetype: nil,
        started_at: nil,
        status: nil,
        attempts: nil,
        max_attempts: nil,
        reports_progress: nil,
        progress: nil
      )

      check_default_values(job_observation)
    end

    it "should not override values with default values when they are passed" do
      job_observation_attributes = {
        person:,
        job_class:,
        filetype: "csv",
        started_at: 10.days.ago,
        status: "in_progress",
        attempts: 3,
        max_attempts: 42,
        reports_progress: true,
        progress: 50
      }

      job_observation = JobObservation.create!(job_observation_attributes)

      expect(job_observation).to have_attributes(job_observation_attributes)
    end

    def check_default_values(job_observation)
      expect(job_observation).to have_attributes(
        person:,
        job_class:,
        filename: nil,
        filetype: "txt",
        reports_progress: false,
        progress: 0,
        status: "planned",
        attempts: 0,
        max_attempts: Delayed::Worker.max_attempts,
        started_at: Time.current
      )
    end
  end

  describe "filename handling" do
    it "#filename_with_extension should append filetype to filename" do
      expect(subject.filename).to eql "subscriptions_to-blorbaels-rants"
      expect(subject.filetype).to eql "csv"
      expect(subject.filename_with_extension).to eql "subscriptions_to-blorbaels-rants.csv"
    end

    it "should normalize filename in setter" do
      subject.filename = "A filename with  many   spaces"

      expect(subject.filename).to eql "A-filename-with-many-spaces"
    end
  end

  describe "job name handling" do
    it "returns human readable job name when translation not found" do
      expect(subject.job_name).to eql("Example export job")
    end

    it "returns i18n translation if translation is available" do
      with_translations(de: {delayed_job: {"export/example_export_job": "Custom Job Name for Example Export"}}) do
        expect(subject.job_name).to eql("Custom Job Name for Example Export")
      end
    end
  end

  describe "state reporting" do
    it "should correctly change model state when reporting in progress" do
      subject.report_in_progress!

      expect(subject.finished_at).to be_nil
      expect(subject.status).to eql("in_progress")
      expect(subject.attempts).to eql(0)
    end

    it "should correctly change model state when reporting success" do
      freeze_time
      subject.report_success!(1)

      expect(subject.finished_at).to eql(Time.current)
      expect(subject.status).to eql("success")
      expect(subject.attempts).to eql(1)
    end

    it "should correctly change model state when reporting error" do
      subject.report_error!(3)

      expect(subject.finished_at).to be_nil
      expect(subject.status).to eql("planned")
      expect(subject.attempts).to eql(3)
    end

    it "should correctly change model state when reporting failure" do
      freeze_time
      subject.update!(attempts: 3)
      subject.report_failure!

      expect(subject.finished_at).to eql(Time.current)
      expect(subject.status).to eql("error")
      expect(subject.attempts).to eql(3)
    end
  end

  describe "progress reporting" do
    it "should not report progress when reports_progress is false" do
      subject.report_progress!(49, 100)

      expect(subject.progress).to be_zero
    end

    context "when reports_progress true" do
      let(:reports_progress) { true }

      it "should not make db query when reported progress stays the same" do
        expect do
          subject.report_progress!(10, 1000)
          subject.report_progress!(11, 1000)
        end.to make.db_queries.with("JobObservation Update": 1)
      end

      it "should correctly set progress with 1 percent steps" do
        calculated_progress_values = []
        calculated_progress_values << subject.progress

        (0..100).each do |i|
          subject.report_progress!(i, 100)
          calculated_progress_values << subject.progress
        end

        expect(calculated_progress_values.uniq).to match_array((0..100).to_a)
      end

      it "should correctly set progress with 10 percent steps" do
        calculated_progress_values = []
        calculated_progress_values << subject.progress

        (9..99).step(10).each do |i|
          subject.report_progress!(i, 100)
          calculated_progress_values << subject.progress
        end

        expect(calculated_progress_values.uniq).to match_array((0..100).step(10).to_a)
      end

      it "should not allow progress over 100" do
        subject.report_progress!(150, 100)

        expect(subject.progress).to eql(100)
      end

      it "should not allow progress under 0" do
        subject.report_progress!(-100, 100)

        expect(subject.progress).to eql(0)
      end
    end
  end

  describe "unfinished counter cache" do
    it "should update counter when job is created" do
      expect(person.reload.unfinished_job_observations_count).to eql(0)

      subject
      expect(person.reload.unfinished_job_observations_count).to eql(1)
    end

    it "should update counter when job observation is destroyed" do
      subject
      expect(person.reload.unfinished_job_observations_count).to eql(1)

      subject.destroy
      expect(person.reload.unfinished_job_observations_count).to eql(0)
    end

    it "should not change count when job changes state to in progress" do
      subject
      expect(person.reload.unfinished_job_observations_count).to eql(1)

      subject.update!(status: "in_progress")
      expect(person.reload.unfinished_job_observations_count).to eql(1)
    end

    it "should update counter with multiple jobs" do
      job_observation = subject
      expect(person.reload.unfinished_job_observations_count).to eql(1)

      other_job_observation = Fabricate(:job_observation, job_class:)
      expect(person.reload.unfinished_job_observations_count).to eql(2)

      job_observation.update!(status: "success")
      expect(person.reload.unfinished_job_observations_count).to eql(1)

      other_job_observation.update!(status: "error")
      expect(person.reload.unfinished_job_observations_count).to eql(0)
    end
  end

  describe "broadcasting" do
    let(:update_channel_name) { "person_#{person.id}_job_observation_updates" }
    let(:notification_channel_name) { "person_#{person.id}_job_observation_notifications" }

    it "should broadcast on create" do
      expect { subject }.to have_broadcasted_overview_update_and_badge_update
    end

    it "should broadcast on update" do
      job_observation = subject

      expect { job_observation.update!(status: "in_progress") }
        .to have_broadcasted_overview_update_and_badge_update
    end

    it "should broadcast on destroy" do
      job_observation = subject

      expect { job_observation.destroy! }
        .to have_broadcasted_overview_update_and_badge_update
    end

    it "should broadcast notification when reporting success" do
      job_observation = subject

      expect { job_observation.report_success!(1) }
        .to have_broadcasted_notification_and_badge_update
    end

    it "should broadcast notification when reporting failure" do
      job_observation = subject

      expect { job_observation.report_failure! }
        .to have_broadcasted_notification_and_badge_update
    end

    it "should broadcast after set timeout only when updating progress" do
      freeze_time

      job_observation = subject
      job_observation.update!(reports_progress: true)

      broadcast_time = Time.current

      expect { job_observation.report_progress!(10, 100) }.to have_broadcasted_to(update_channel_name)
      expect(job_observation.last_progress_update_broadcasted_at).to eql(broadcast_time)

      expect { job_observation.report_progress!(20, 100) }.not_to have_broadcasted_to(update_channel_name)
      expect(job_observation.last_progress_update_broadcasted_at).to eql(broadcast_time)

      travel(6.seconds)
      broadcast_time = Time.current

      expect { job_observation.report_progress!(30, 100) }.to have_broadcasted_to(update_channel_name)
      expect(job_observation.last_progress_update_broadcasted_at).to eql(broadcast_time)

      expect { job_observation.report_progress!(40, 100) }.not_to have_broadcasted_to(update_channel_name)
      expect(job_observation.last_progress_update_broadcasted_at).to eql(broadcast_time)
    end

    it "should still successfully complete job if broadcasting fails with redis exceptions" do
      expect(subject).to receive(:broadcast_replace_to).and_raise(Redis::ConnectionError)
      expect(Sentry).to receive(:capture_exception).with(Redis::ConnectionError)

      subject.report_success!(1)

      expect(subject.status).to eql("success")
    end

    def have_broadcasted_overview_update_and_badge_update
      have_broadcasted_to(update_channel_name)
        .and have_broadcasted_to(notification_channel_name)
        .with(a_string_matching(/target="job-observations-link-with-badge"/))
    end

    def have_broadcasted_notification_and_badge_update
      have_broadcasted_to(notification_channel_name)
        .with(a_string_matching(/target="job-observation-notifications-container"/))
        .and have_broadcasted_to(notification_channel_name)
        .with(a_string_matching(/target="job-observations-link-with-badge"/))
    end
  end

  describe "download permissions" do
    it "knows if the file is downloadable for a person" do
      file_double = double("attachement")
      expect(subject).to receive(:generated_file).and_return(file_double)
      expect(file_double).to receive(:attached?).and_return(true)

      expect(subject.downloadable?(person)).to be true
    end

    it "is not downloadable for a different person" do
      other_person = people(:bottom_member)

      expect(subject.downloadable?(other_person)).to be false
    end
  end

  describe "attachment" do
    it "allows writing data" do
      expect do
        subject.write(data)
      end.to change(subject.generated_file, :attached?).from(false).to(true)
    end
  end
end
