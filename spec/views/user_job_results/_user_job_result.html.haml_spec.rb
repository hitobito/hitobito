# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "user_job_results/_user_job_result.html.haml" do
  let(:person) { people(:top_leader) }
  let(:user_job_result) { Fabricate(:user_job_result, person_id: person.id, status: "success", attempts: 1) }

  let(:dom) do
    render locals: { user_job_result: }
    Capybara::Node::Simple.new(rendered)
  end

  before do
    allow(Auth).to receive(:current_person).and_return(person)
  end

  it "shows all job information" do
    expect(dom).to have_css(".fas.fa-circle-check")
    expect(dom).to have_content("Test job")
    expect(dom).to have_content("Versuche: 1/2")
    expect(dom).to have_content("Dieser Job hat keinen nachverfolgbaren Fortschritt")
    expect(dom).not_to have_css(".progress")
    expect(dom).to have_content("Startzeitpunkt")
    expect(dom).to have_content("Endzeitpunkt")
    expect(dom).not_to have_css(".fas.fa-download")
  end

  it "shows progress bar for successful job with progress" do
    user_job_result.update!(reports_progress: true)
    user_job_result.update!(progress: 100)

    expect(dom).to have_css(".fas.fa-circle-check")
    expect(dom).to have_css(".progress")
    expect(dom).to have_css("div[class='progress-bar'][style='width: 100%']")
    expect(dom).to have_content("100%")
  end

  it "should show download icon if file is downloadable" do
    user_job_result.write("Some wonderful file content")

    expect(dom).to have_css(".fas.fa-download")
  end
end
