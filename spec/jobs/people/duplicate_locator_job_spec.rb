# frozen_string_literal: true

#  Copyright (c) 2023-2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe People::DuplicateLocatorJob do
  subject(:job) { described_class.new }

  it 'calls Locator run and reschedules for next day' do
    freeze_time
    expect(People::DuplicateLocator).to receive_message_chain(:new, :run)
    expect { job.perform }.to not_change { Person.count }
      .and change { job.delayed_jobs.count }.by(1)
    expect(job.delayed_jobs.first.run_at).to be_within(10.minutes).of(1.day.from_now)
  end
end
