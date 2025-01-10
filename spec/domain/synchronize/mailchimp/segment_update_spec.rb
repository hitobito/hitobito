# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Synchronize::Mailchimp::SegmentUpdate do
  def prepare_update(tag_id: 1, local_emails: [], remote_emails: [], obsolete_emails: [])
    described_class.new(tag_id, local_emails, remote_emails, obsolete_emails).prepare
  end

  before { stub_const("Synchronize::Mailchimp::SegmentUpdate::SLICE_SIZE", 2) }

  it "batches add operations" do
    local_emails = %w[a b c d e]
    expect(prepare_update(local_emails:)).to eq [
      [1, {members_to_add: %w[a b], members_to_remove: []}],
      [1, {members_to_add: %w[c d], members_to_remove: []}],
      [1, {members_to_add: %w[e], members_to_remove: []}]
    ]
  end

  it "batches remove operations" do
    remote_emails = %w[a b c d e]
    expect(prepare_update(remote_emails:)).to eq [
      [1, {members_to_add: [], members_to_remove: %w[a b]}],
      [1, {members_to_add: [], members_to_remove: %w[c d]}],
      [1, {members_to_add: [], members_to_remove: %w[e]}]
    ]
  end

  it "batches using larger add batch" do
    local_emails = %w[a b c]
    remote_emails = %w[e]
    expect(prepare_update(local_emails:, remote_emails:)).to eq [
      [1, {members_to_add: %w[a b], members_to_remove: %w[e]}],
      [1, {members_to_add: %w[c], members_to_remove: []}]
    ]
  end

  it "batches using larger remove batch" do
    local_emails = %w[e]
    remote_emails = %w[a b c]
    expect(prepare_update(local_emails:, remote_emails:)).to eq [
      [1, {members_to_add: %w[e], members_to_remove: %w[a b]}],
      [1, {members_to_add: [], members_to_remove: %w[c]}]
    ]
  end

  it "is nil if tag_id is nil" do
    local_emails = %w[a]
    expect(prepare_update(tag_id: nil, local_emails:)).to be_nil
  end

  it "is nil if tag_id is blank" do
    local_emails = %w[a]
    expect(prepare_update(tag_id: "", local_emails:)).to be_nil
  end

  it "is nil if local emails equal remote emails" do
    local_emails = %w[a]
    remote_emails = %w[a]
    expect(prepare_update(local_emails:, remote_emails:)).to be_nil
  end

  it "is nil if local email is included in obsolete emails" do
    local_emails = %w[a]
    remote_emails = %w[]
    obsolete_emails = %w[a]
    expect(prepare_update(local_emails:, remote_emails:, obsolete_emails:)).to be_nil
  end

  it "is nil if remote email is included in obsolete emails" do
    local_emails = %w[]
    remote_emails = %w[a]
    obsolete_emails = %w[a]
    expect(prepare_update(local_emails:, remote_emails:, obsolete_emails:)).to be_nil
  end
end
