#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe UserJobResultsHelper do
  # Source - https://stackoverflow.com/a/23655457
  # Posted by Sebastian vom Meer
  # Retrieved 2026-03-02, License - CC BY-SA 3.0
  before { helper.instance_variable_set(:@virtual_path, "user_job_results.user_job_result") }

  it "icon for status in_progress should have spin animation class" do
    icon = Capybara::Node::Simple.new(helper.job_status_icon(:in_progress))
    expect(icon).to have_css(".fa-spin-pulse")
  end

  it "icons that are not for status in_progress should not have spin animation class" do
    icon = Capybara::Node::Simple.new(helper.job_status_icon(:success))
    expect(icon).not_to have_css(".fa-spin-pulse")
  end

  it "should use correct format for job timestamp" do
    timestamp = Time.new(2000, 1, 1, 3).to_i
    job_timestamp = helper.job_timestamp(timestamp)
    expect(job_timestamp).to eql("01.01.2000 03:00")
  end
end
