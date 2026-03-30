#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe DownloadCleanerJob do
  subject { DownloadCleanerJob.new }

  let(:person) { people(:top_leader) }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:event_filter) { Event::Filter.new(group, nil, "all", 2012, false) }

  before do
    allow(Auth).to receive(:current_person).and_return(person)
  end

  it "removes files and gets rescheduled" do
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  it "removes files older than one day" do
    download_file(Time.zone.now)
    download_file(1.day.ago + 1.hour)
    download_file(1.day.ago - 1.hour)
    download_file(1.day.ago - 14.hours)

    expect do
      subject.perform_internal
    end.to change(UserJobResult, :count).from(4).to(2)
  end

  private

  def download_file(time)
    job = Export::EventsExportJob.new(:csv, user.id, group.id, event_filter.to_h, filename: "event_export")

    travel_to(time) do
      job.enqueue!
    end

    file = job.user_job_result
    file.write("testfilecontent")
    file
  end
end
