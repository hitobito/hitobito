#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe :user_job_results, js: true do
  include DelayedJobSpecHelper

  let(:top_leader) { people(:top_leader) }

  before do
    allow(Auth).to receive(:current_person).and_return(top_leader)
    sign_in(top_leader)
  end

  it "should show all job information" do
    job = Examples::SuccessfulUserManagedJob.new
    enqueue_and_run_job(job)
    visit user_job_results_path

    expect(page).to have_css(".fas.fa-circle-check")
    expect(page).to have_content("Custom job name")
    expect(page).to have_content("Versuche: 1/2")
    expect(page).to have_content("Dieser Job hat keinen nachverfolgbaren Fortschritt")
    expect(page).not_to have_css(".progress")
    expect(page).to have_content("Startzeitpunkt")
    expect(page).to have_content("Endzeitpunkt")
    expect(page).not_to have_css(".fas.fa-download")
  end

  it "should show progress bar for successful job with progress" do
    job = Examples::UserManagedJobWithProgress.new
    enqueue_and_run_job(job)
    visit user_job_results_path

    expect(page).to have_css(".fas.fa-circle-check")
    expect(page).to have_css(".progress")
    expect(page).to have_css("div[class='progress-bar'][style='width: 100%']")
    expect(page).to have_content("100%")
  end

  it "should show download icon if file is downloadable" do
    job = Examples::UserManagedJobWithProgress.new
    enqueue_and_run_job(job)
    allow(job).to receive(:downloadable?).and_return(true)
    visit user_job_results_path

    expect(page).not_to have_content(".fas.fa-download")
  end

  it "should update user job results live" do
    visit user_job_results_path
    expect(page).not_to have_content("Custom job name")

    job = Examples::SuccessfulUserManagedJob.new
    enqueue_and_run_job(job)

    expect(page).to have_content("Custom job name")
  end

  it "should show notification when job has successfully completed" do
    visit user_job_results_path

    expect(page).not_to have_content("Job erfolgreich abgeschlossen")

    job = Examples::SuccessfulUserManagedJob.new
    enqueue_and_run_job(job)

    expect(page).to have_content("Job erfolgreich abgeschlossen")
  end

  it "should show notification when job has failed" do
    visit root_path

    expect(page).not_to have_content("Fehler bei Jobausführung aufgetreten")

    job = Examples::UnsuccessfulUserManagedJob.new
    enqueued_job = job.enqueue!
    2.times { run_enqueued_job(enqueued_job) }

    expect(page).to have_content("Fehler bei Jobausführung aufgetreten")
  end
end
