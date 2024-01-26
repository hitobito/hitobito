
# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::OptInCleanupJob do
  include Subscriptions::SpecHelper

  let(:person) { people(:top_leader) }
  let(:leaders) { mailing_lists(:leaders) }
  let(:members) { mailing_lists(:members) }

  def condition(id = nil)
    return "handler like '%Subscriptions::OptInCleanupJob\nmailing_list_id: #{id}%'" if id
    "handler like '%Subscriptions::OptInCleanupJob%'"
  end

  subject(:job) { described_class.new }

  it 'does not enqueue if opt_in list has no people subscriptions' do
    leaders.update!(subscribable_mode: :opt_in)
    expect { job.perform }.not_to change(Delayed::Job.where(condition), :count)
  end

  it 'does not enqueue if list has people subscriptions but is not opt in' do
    leaders.subscriptions.create!(subscriber: person)
    expect { job.perform }.not_to change(Delayed::Job.where(condition), :count)
  end

  it 'does enqueue job for each list that has people subscription and is opt in' do
    leaders.update!(subscribable_mode: :opt_in)
    leaders.subscriptions.create!(subscriber: person)

    members.update!(subscribable_mode: :opt_in)
    members.subscriptions.create!(subscriber: person)
    expect do
      job.perform
    end.to change(Delayed::Job.where(condition(leaders.id)), :count).by(1)
      .and change(Delayed::Job.where(condition(members.id)), :count).by(1)
  end
end
