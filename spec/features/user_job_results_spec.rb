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

  context "live update and notifications" do
    before do
      Delayed::Worker.max_attempts = 1
    end

    it "should receive live updates for user job results of current user" do
      visit user_job_results_path
      expect(page).to have_content("Jobübersicht")

      within "#user_job_results" do
        expect(page).not_to have_content("Job enqueued by current user")
        expect(page).not_to have_content("Job enqueued by other user")

        enqueue_job_by_current_and_other_user(Examples::SuccessfulUserManagedJob)
        expect(Delayed::Worker.new.work_off).to eql([2, 0])

        expect(page).to have_content("Job enqueued by current user")
        expect(page).not_to have_content("Job enqueued by other user")
      end
    end

    it "should show notification when job of current user has successfully completed" do
      visit root_path

      expect(page).not_to have_content("Job erfolgreich abgeschlossen")
      expect(page).not_to have_content("Job enqueued by current user")
      expect(page).not_to have_content("Job enqueued by other user")

      enqueue_job_by_current_and_other_user(Examples::SuccessfulUserManagedJob)
      expect(Delayed::Worker.new.work_off).to eql([2, 0])

      expect(page).to have_content("Job erfolgreich abgeschlossen", count: 1)
      expect(page).to have_content("Job enqueued by current user")
      expect(page).not_to have_content("Job enqueued by other user")
    end

    it "should show notification when job of current user has failed" do
      visit root_path

      expect(page).not_to have_content("Fehler der Jobausführung aufgetreten")
      expect(page).not_to have_content("Job enqueued by current user")
      expect(page).not_to have_content("Job enqueued by other user")

      enqueue_job_by_current_and_other_user(Examples::UnsuccessfulUserManagedJob)
      expect(Delayed::Worker.new.work_off).to eql([0, 2])

      expect(page).to have_content("Fehler bei Jobausführung aufgetreten", count: 1)
      expect(page).to have_content("Job enqueued by current user")
      expect(page).not_to have_content("Job enqueued by other user")
    end

    def enqueue_job_by_current_and_other_user(job_class)
      user_job = job_class.new
      user_job.job_name = "Job enqueued by current user"
      user_job.enqueue!

      allow(Auth).to receive(:current_person).and_return(people(:bottom_member))
      other_user_job = job_class.new
      user_job.job_name = "Job enqueued by other user"
      other_user_job.enqueue!
      allow(Auth).to receive(:current_person).and_return(top_leader)
    end
  end

  it "should show user job results for jobs that were enqueued from another job" do
    allow(Auth).to receive(:current_person).and_call_original
    visit user_job_results_path
    expect(page).to have_content("Jobübersicht")

    job = Examples::UserManagedParentJob.new
    job.user_id = top_leader.id

    enqueue_and_run_job(job)
    Delayed::Worker.new.work_off

    within "#user_job_results" do
      expect(page).to have_content("Parent Job", count: 1)
      expect(page).to have_content("Child Job", count: 3)
    end
  end

  it "should update pagination when jobs are enqueued" do
    allow(Kaminari.config).to receive(:default_per_page).and_return(2)
    job = Examples::SuccessfulUserManagedJob.new
    visit user_job_results_path
    expect(page).to have_content("Jobübersicht")

    within "#content" do
      job.job_name = "First job"
      2.times { job.enqueue! }

      expect(page).to have_content("First job", count: 2)
      expect(page).not_to have_content("Letzte")

      job.job_name = "Second job"
      job.enqueue!

      expect(page).to have_content("First job", count: 1)
      expect(page).to have_content("Second job", count: 1)
      expect(page).to have_content("Letzte")

      # Go to second page of pagination
      click_link("2", match: :first)
      expect(page).to have_content("First job", count: 1)
      expect(page).not_to have_content("Second job")
      expect(page).to have_content("Erste")

      job.enqueue!

      expect(page).to have_content("First job", count: 2)
      expect(page).not_to have_content("Second job")
      expect(page).to have_content("Erste")

      # Go back to first page of pagination
      click_link("1", match: :first)
      expect(page).to have_content("Second job", count: 2)
      expect(page).not_to have_content("First job")
      expect(page).to have_content("Letzte")
    end
  end
end
