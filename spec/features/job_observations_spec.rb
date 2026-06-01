#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe :job_observations, js: true do
  include DelayedJobSpecHelper

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before do
    allow(Delayed::Worker).to receive(:max_attempts).and_return(1)

    allow(Auth).to receive(:current_person).and_return(top_leader)
    sign_in(top_leader)
  end

  it "should receive live updates for job observations of current user" do
    enqueue_job_by_current_and_other_user(Test::SuccessfulObservableJob)

    visit job_observations_path
    expect(page).to have_content("Jobübersicht")

    within "#job_observations" do
      expect(page).to have_content("Current user job", count: 1)
      expect(page).not_to have_content("Other user job")
      expect(page).to have_css(".fas.fa-circle-notch", count: 1)

      enqueue_job_by_current_and_other_user(Test::SuccessfulObservableJob)

      expect(page).to have_content("Current user job", count: 2)
      expect(page).not_to have_content("Other user job")
      expect(page).to have_css(".fas.fa-circle-notch", count: 2)

      expect(Delayed::Worker.new.work_off).to eql([4, 0])

      expect(page).to have_content("Current user job", count: 2)
      expect(page).not_to have_content("Other user job")
      expect(page).to have_css(".fas.fa-circle-check", count: 2)
    end
  end

  it "should show notification when job of current user has successfully completed" do
    enqueue_job_by_current_and_other_user(Test::SuccessfulObservableJob)

    visit root_path
    expect(page).to have_content("Top Leader")

    expect(page).not_to have_content("Job erfolgreich abgeschlossen")
    expect(page).not_to have_content("Current user job")
    expect(page).not_to have_content("Other user job")

    expect(Delayed::Worker.new.work_off).to eql([2, 0])

    expect(page).to have_content("Job erfolgreich abgeschlossen", count: 1)
    expect(page).to have_content("Current user job", count: 1)
    expect(page).not_to have_content("Other user job")
  end

  it "should show notification when job of current user has failed" do
    enqueue_job_by_current_and_other_user(Test::UnsuccessfulObservableJob)

    visit root_path
    expect(page).to have_content("Top Leader")

    expect(page).not_to have_content("Fehler der Jobausführung aufgetreten")
    expect(page).not_to have_content("Current user job")
    expect(page).not_to have_content("Other user job")

    expect(Delayed::Worker.new.work_off).to eql([0, 2])

    expect(page).to have_content("Fehler bei Jobausführung aufgetreten", count: 1)
    expect(page).to have_content("Current user job", count: 1)
    expect(page).not_to have_content("Other user job")
  end

  it "should update pagination when jobs are enqueued" do
    allow(Kaminari.config).to receive(:default_per_page).and_return(2)

    job = Test::SuccessfulObservableJob.new
    2.times do
      delayed_job = job.enqueue!
      JobObservation.where(delayed_job:).update!(job_class: "FirstJob")
    end

    visit job_observations_path
    expect(page).to have_content("Jobübersicht")

    within "#content" do
      expect(page).to have_content("First job", count: 2)
      expect(page).not_to have_content("Letzte")

      delayed_job = job.enqueue!
      JobObservation.where(delayed_job:).update!(job_class: "SecondJob")

      expect(page).to have_content("First job", count: 1)
      expect(page).to have_content("Second job", count: 1)
      expect(page).to have_content("Letzte")

      # Go to second page of pagination
      click_link("2", match: :first)
      expect(page).to have_content("First job", count: 1)
      expect(page).not_to have_content("Second job")
      expect(page).to have_content("Erste")

      delayed_job = job.enqueue!
      JobObservation.where(delayed_job:).update!(job_class: "SecondJob")

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

  it "should update job observations link badge" do
    visit root_path
    expect(page).to have_content("Top Leader")

    expect(page).to have_css("#job-observations-link-with-badge")
    expect(page).not_to have_css("#job-observations-link-with-badge .badge")

    enqueued_job = Test::SuccessfulObservableJob.new.enqueue!

    refresh
    expect(page).to have_content("Top Leader")

    expect(page).to have_css("#job-observations-link-with-badge .badge", text: 1)

    in_progress_job = Test::SuccessfulObservableJob.new
    enqueued_in_progress_job = in_progress_job.enqueue!
    in_progress_job.job_observation.report_in_progress!

    expect(page).to have_css("#job-observations-link-with-badge .badge", text: 2)

    run_enqueued_job(enqueued_job)

    expect(page).to have_css("#job-observations-link-with-badge .badge", text: 1)

    run_enqueued_job(enqueued_in_progress_job)

    expect(page).to have_css("#job-observations-link-with-badge")
    expect(page).not_to have_css("#job-observations-link-with-badge .badge")
  end

  it "should establish web socket connection when needs_web_socket_connection on person is truthy" do
    Test::SuccessfulObservableJob.new.enqueue!

    visit root_path
    expect(page).to have_content("Top Leader")

    expect(page).to have_css("turbo-cable-stream-source", visible: false, count: 1)

    visit job_observations_path
    expect(page).to have_content("Jobübersicht")

    expect(page).to have_css("turbo-cable-stream-source", visible: false, count: 2)
  end

  it "should not establish web socket connection when needs_web_socket_connection on person is falsy" do
    visit root_path
    expect(page).to have_content("Top Leader")

    expect(page).not_to have_css("turbo-cable-stream-source", visible: false)

    visit job_observations_path
    expect(page).to have_content("Jobübersicht")

    expect(page).not_to have_css("turbo-cable-stream-source", visible: false)
  end

  it "should automatically establish websocket connection when job is enqueued from ui" do
    visit group_path(groups(:top_group))
    expect(page).to have_content("TopGroup")

    expect(page).not_to have_css("turbo-cable-stream-source", visible: false)
    expect(page).not_to have_css("#job-observations-link-with-badge .badge")

    click_link("CSV Untergruppen")

    expect(page).to have_css("turbo-cable-stream-source", visible: false, count: 1)
    expect(page).to have_css("#job-observations-link-with-badge .badge", text: 1)

    expect(Delayed::Worker.new.work_off).to eql([1, 0])

    expect(page).not_to have_css("#job-observations-link-with-badge .badge")
    expect(page).to have_content("Job erfolgreich abgeschlossen")
  end

  def enqueue_job_by_current_and_other_user(job_class)
    user_job = job_class.new
    user_delayed_job = user_job.enqueue!
    JobObservation.where(delayed_job: user_delayed_job).update!(job_class: "CurrentUserJob")

    allow(Auth).to receive(:current_person).and_return(bottom_member)

    other_user_job = job_class.new
    other_user_delayed_job = other_user_job.enqueue!
    JobObservation.where(delayed_job: other_user_delayed_job).update!(job_class: "OtherUserJob")

    allow(Auth).to receive(:current_person).and_return(top_leader)
  end
end
