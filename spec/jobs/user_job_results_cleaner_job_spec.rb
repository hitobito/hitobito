#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe UserJobResultsCleanerJob do
  include DelayedJobSpecHelper

  subject { UserJobResultsCleanerJob.new }

  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:filter) do
    {range: "all", year: "2012"}
  end

  before do
    allow(Auth).to receive(:current_person).and_return(person)
  end

  it "removes user job results and gets rescheduled" do
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  it "removes user job results for jobs that finished more than one day ago" do
    download_file(Time.zone.now)
    download_file(1.day.ago + 1.hour)
    download_file(1.day.ago - 1.hour)
    download_file(1.day.ago - 14.hours)

    expect do
      subject.perform_internal
    end.to change(UserJobResult, :count).from(4).to(2)
  end

  # User Job Results are removed by end_timestamp to not remove user job results
  # of jobs with a total retry time longer than 1 day
  it "doesnt remove user job results for jobs that have not finished yet" do
    unfinished_job = Examples::SuccessfulUserManagedJob.new
    finished_job = Examples::SuccessfulUserManagedJob.new

    travel_to(2.days.ago) do
      unfinished_job.enqueue!
      finished_job.enqueue!
      finished_job.user_job_result.report_failure!
    end

    expect do
      subject.perform_internal
    end.to change(UserJobResult, :count).from(2).to(1)
  end

  it "removes user job results that dont have a delayed job id" do
    download_file(Time.current)

    orphaned_user_job_result = download_file(Time.current)
    orphaned_user_job_result.update!(delayed_job_id: nil)

    expect do
      subject.perform_internal
    end.to change(UserJobResult, :count).from(2).to(1)
  end

  it "removes user job results where end timestamp is nil and associated delayed job doesnt exist" do
    download_file(Time.current)

    orphaned_user_job_result = download_file(Time.current)
    orphaned_user_job_result.update!(end_timestamp: nil)
    orphaned_user_job_result.delayed_job.destroy!

    expect(orphaned_user_job_result.delayed_job_id).not_to be_nil
    expect(orphaned_user_job_result.reload.delayed_job).to be_nil
    expect do
      subject.perform_internal
    end.to change(UserJobResult, :count).from(2).to(1)
  end

  it "removes user job results where end timestamp is nil and associated delayed job has finished with failure" do
    download_file(Time.current)

    orphaned_user_job_result = download_file(Time.current)
    orphaned_user_job_result.update!(end_timestamp: nil)
    orphaned_user_job_result.delayed_job.update!(failed_at: Time.current)

    expect do
      subject.perform_internal
    end.to change(UserJobResult, :count).from(2).to(1)
  end

  private

  def download_file(time)
    export_job = Export::EventsExportJob.new(:csv, person.id, group.id, filter, filename: "event_export")

    travel_to(time) do
      export_job.enqueue!
      export_job.user_job_result.report_success!(1)
    end

    user_job_result = export_job.user_job_result
    user_job_result.write("testfilecontent")
    user_job_result
  end
end
