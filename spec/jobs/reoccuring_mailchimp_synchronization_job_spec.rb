# frozen_string_literal: true

#  Copyright (c) 2018-2023, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ReoccuringMailchimpSynchronizationJob do
  let(:group) { groups(:top_group) }

  def create(state = nil, mailchimp_last_synced_at = nil)
    Fabricate(:mailing_list, group: group, mailchimp_list_id: 1, mailchimp_api_key: "abc-us1").tap do |list|
      data = case state
      when :failed then {exception: ArgumentError.new("ouch")}
      when :success then {foo: {total: 1, success: 1}}
      when :partial then {foo: {failed: 1}, bar: {success: 1}}
      when :unchanged then {}
      end
      list.update!(mailchimp_last_synced_at:, mailchimp_result: Synchronize::Mailchimp::Result.new(data)) if data
    end
  end

  subject { ReoccuringMailchimpSynchronizationJob.new }

  it "ignores list not linked" do
    Fabricate(:mailing_list, group: group)
    expect { subject.perform_internal }.not_to(change { Delayed::Job.count })
  end

  describe "failed state" do
    it "ignores recently failed" do
      create(:failed, 6.days.ago)
      expect { subject.perform_internal }.not_to(change { Delayed::Job.count })
    end

    it "uses list failed more than 7 days.ago" do
      create(:failed, 8.days.ago)
      expect { subject.perform_internal }.to(change { Delayed::Job.count })
    end

    it "uses list with nil mailchimp_last_synced_at" do
      create(:failed, nil)
      expect { subject.perform_internal }.to(change { Delayed::Job.count })
    end
  end

  [:success, :partial, :unchanged].each do |state|
    it "enqueues job for #{state}" do
      create(state)
      expect { subject.perform_internal }.to change { Delayed::Job.count }.by(1)
    end
  end
end
