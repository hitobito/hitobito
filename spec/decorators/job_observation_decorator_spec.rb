#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JobObservationDecorator do
  let(:job_observation) { Fabricate(:job_observation) }

  subject { described_class.new(job_observation) }

  it "should give icon for status in_progress spin animation class" do
    subject.report_in_progress!
    icon = Capybara::Node::Simple.new(subject.status_icon)

    expect(icon).to have_css(".fa-spin-pulse")
  end

  it "icons that are not for status in_progress should not have spin animation class" do
    subject.report_success!(1)
    icon = Capybara::Node::Simple.new(subject.status_icon)

    expect(icon).not_to have_css(".fa-spin-pulse")
  end

  it "should correctly format job timestamp" do
    timestamp = Time.zone.parse("01.01.2000 03:00")
    subject.started_at = timestamp

    expect(subject.formatted_started_at).to eql("01.01.2000 03:00")
  end

  it "should not add download url value to stimulus attributes if generated file is not attached" do
    expect(subject.stimulus_attributes).to have_key("data-controller")

    expect(subject.stimulus_attributes)
      .not_to have_key("data-job-observation-notification-generated-file-download-url-value")
  end

  it "should add download url value to stimulus attributes if generated file is attached" do
    subject.write("Some content")

    expect(subject.stimulus_attributes)
      .to have_key("data-controller")
      .and have_key("data-job-observation-notification-generated-file-download-url-value")
  end
end
