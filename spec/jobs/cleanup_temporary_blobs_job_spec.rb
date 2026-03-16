#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe CleanupTemporaryBlobsJob do
  subject { CleanupTemporaryBlobsJob.new }

  it "purges expired blobs and gets rescheduled" do
    subject.perform
    expect(subject.delayed_jobs).to be_exists
  end

  it "removes temporary blobs older than one day" do
    create_blob(temporary: false, created_at: 2.days.ago)
    create_blob(temporary: true, created_at: 12.hours.ago)

    create_blob(temporary: true, created_at: 25.hours.ago)
    create_blob(temporary: true, created_at: 2.days.ago)

    expect do
      subject.perform_internal
    end.to change(ActiveStorage::Blob.temporary, :count).from(3).to(1)
  end

  private

  def create_blob(temporary:, created_at:)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("some cool content that should not stay for long"),
      filename: "file.txt",
      content_type: "text/plain"
    ).tap do |blob|
      blob.update!(temporary:, created_at:)
    end
  end
end
