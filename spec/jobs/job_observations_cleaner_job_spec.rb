#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JobObservationsCleanerJob do
  include DelayedJobSpecHelper

  subject { JobObservationsCleanerJob.new }

  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:filter) do
    {range: "all", year: "2012"}
  end

  before do
    allow(Auth).to receive(:current_person).and_return(person)
  end

  it "removes job observations and gets rescheduled" do
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  it "removes job observations for jobs that finished more than one day ago" do
    download_file(Time.zone.now)
    download_file(1.day.ago + 1.hour)
    download_file(1.day.ago - 1.hour)
    download_file(1.day.ago - 14.hours)

    expect do
      subject.perform_internal
    end.to change(JobObservation, :count).from(4).to(2)
  end

  # job observations are removed by finished_at to not remove job observations
  # of jobs with a total retry time longer than 1 day
  it "doesnt remove job observations for jobs that have not finished yet" do
    unfinished_job = Examples::SuccessfulObservableJob.new
    finished_job = Examples::SuccessfulObservableJob.new

    travel_to(2.days.ago) do
      unfinished_job.enqueue!
      finished_job.enqueue!
      finished_job.job_observation.report_failure!
    end

    expect do
      subject.perform_internal
    end.to change(JobObservation, :count).from(2).to(1)
  end

  it "removes job observations that dont have a delayed job id" do
    download_file(Time.current)

    orphaned_job_observation = download_file(Time.current)
    orphaned_job_observation.update!(delayed_job_id: nil)

    expect do
      subject.perform_internal
    end.to change(JobObservation, :count).from(2).to(1)
  end

  it "removes job observations where end timestamp is nil and associated delayed job doesnt exist" do
    download_file(Time.current)

    orphaned_job_observation = download_file(Time.current)
    orphaned_job_observation.update!(finished_at: nil)
    orphaned_job_observation.delayed_job.destroy!

    expect(orphaned_job_observation.delayed_job_id).not_to be_nil
    expect(orphaned_job_observation.reload.delayed_job).to be_nil
    expect do
      subject.perform_internal
    end.to change(JobObservation, :count).from(2).to(1)
  end

  it "removes job observations where end timestamp is nil and associated delayed job has finished with failure" do
    download_file(Time.current)

    orphaned_job_observation = download_file(Time.current)
    orphaned_job_observation.update!(finished_at: nil)
    orphaned_job_observation.delayed_job.update!(failed_at: Time.current)

    expect do
      subject.perform_internal
    end.to change(JobObservation, :count).from(2).to(1)
  end

  private

  def download_file(time)
    export_job = Export::EventsExportJob.new(:csv, person.id, group.id, filter, filename: "event_export")

    travel_to(time) do
      export_job.enqueue!
      export_job.job_observation.report_success!(1)
    end

    job_observation = export_job.job_observation
    job_observation.write("testfilecontent")
    job_observation
  end
end
