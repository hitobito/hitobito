#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe DownloadCleanerJob do
  subject { DownloadCleanerJob.new }

  it "removes files and gets rescheduled" do
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  it "removes files older then one day" do
    now_file = download_filename("now", Time.now.to_i)
    one_day_file = download_filename("one_day", 1.day.ago.to_i)
    two_days_file = download_filename("one_day", 2.days.ago.to_i)

    generate_test_file(now_file)
    generate_test_file(one_day_file)
    generate_test_file(two_days_file)

    subject.perform_internal

    expect(File.exist?("#{AsyncDownloadFile::DIRECTORY}/#{now_file}.txt")).to be true
    expect(File.exist?("#{AsyncDownloadFile::DIRECTORY}/#{one_day_file}.txt")).to be false
    expect(File.exist?("#{AsyncDownloadFile::DIRECTORY}/#{two_days_file}.txt")).to be false
  end

  private

  def generate_test_file(filename)
    AsyncDownloadFile.new(filename).write("testfile")
  end

  def download_filename(filename, time)
    "#{filename}_#{time}-1234"
  end
end
