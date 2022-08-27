# encoding: utf-8

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe DownloadCleanerJob do

  subject { DownloadCleanerJob.new }

  it 'removes files and gets rescheduled' do
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  it 'removes files older then one day' do
    download_file('file', Time.now.to_i)
    download_file('file', 23.hours.ago.to_i)

    download_file('file', 25.hours.ago.to_i)
    download_file('file', 36.hours.ago.to_i)

    expect do
      subject.perform_internal
    end.to change(AsyncDownloadFile, :count).from(4).to(2)
  end

  private

  def download_file(filename, time)
    file = AsyncDownloadFile.from_filename("#{filename}_#{time}-1234")
    file.write('testfilecontent')
    file
  end

end
