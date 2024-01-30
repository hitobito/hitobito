# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriptions::OptInCleanupJob do
  include Subscriptions::SpecHelper

  let(:role) { roles(:top_leader) }
  let(:person) { role.person }
  let(:group) { role.group }
  let(:list) { mailing_lists(:leaders).tap { |l| l.update!(subscribable_mode: :opt_in) } }

  subject(:job) { described_class.new(list.id) }

  it 'clears obsolete subscription' do
    create_subscription(person)

    expect { job.perform }.to(change { person.subscriptions.count })
  end

  it 'keeps valid subscription' do
    create_subscription(group, false, role.class)
    create_subscription(person)

    expect { job.perform }.not_to(change { person.subscriptions.count })
  end
end
