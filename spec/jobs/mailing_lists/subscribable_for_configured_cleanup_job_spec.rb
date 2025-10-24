# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailingLists::SubscribableForConfiguredCleanupJob do
  let(:leaders) { mailing_lists(:leaders) }
  let(:member) { people(:bottom_member) }

  subject(:job) { described_class.new(leaders.id) }

  before do
    leaders.subscriptions.create!(subscriber: member)
    leaders.update!(subscribable_for: :configured)
  end

  it "clears person subscription not included in configured role subscriptions" do
    expect do
      job.perform
    end.to change { leaders.subscriptions.count }.by(-1)
  end

  it "keeps person subscription included in configured role subscriptions" do
    Fabricate(Group::BottomLayer::Leader.sti_name, person: member, group: groups(:bottom_layer_one))
    expect do
      job.perform
    end.not_to change { leaders.subscriptions.count }
  end
end
