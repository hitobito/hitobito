#  Copyright (c) 2025-2026, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require "spec_helper"

describe Bulk::TagRemoveJob do
  let(:tagged_people) { [people(:top_leader), people(:bottom_member)] }
  let(:ids) { tagged_people.map(&:id) }

  subject(:job) { described_class.new(ids, ["foo", "bar"]) }

  before { tagged_people.each { |person| person.update!(tag_list: %w[foo bar keep]) } }

  it "removes the tags from all people" do
    job.perform

    tagged_people.each { |person| expect(person.reload.tag_list).to eq ["keep"] }
  end

  it "does not touch people outside of the given ids" do
    other = Fabricate(:person, tag_list: %w[foo bar])

    job.perform

    expect(other.reload.tag_list).to match_array(%w[foo bar])
  end

  it "processes the ids in batches" do
    stub_const("Bulk::TagBulkJob::BATCH_SIZE", 1)

    expect(TagList).to receive(:new).twice.and_call_original

    job.perform

    tagged_people.each { |person| expect(person.reload.tag_list).to eq ["keep"] }
  end
end
