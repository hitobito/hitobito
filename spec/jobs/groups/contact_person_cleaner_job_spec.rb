# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Groups::ContactPersonCleanerJob do
  include ActiveJob::TestHelper

  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  subject { described_class.new }

  it "reschedules to tomorrow at 4am" do
    subject.perform

    expect(subject.delayed_jobs.last.run_at).to eq(Time.zone.tomorrow
      .at_beginning_of_day
      .change(hour: 4)
      .in_time_zone)
  end

  it "clears contact person from group when no role exists and creates log entry" do
    person.roles.destroy_all
    expect { subject.perform }
      .to change { group.reload.contact }.from(person).to(nil)
      .and change { HitobitoLogEntry.count }.by(1)

    log_entry = HitobitoLogEntry.last
    # rubocop:todo Layout/LineLength
    expect(log_entry.message).to eq "Contact person of Bottom One was removed, due to person not having any active member role in Bottom One"
    # rubocop:enable Layout/LineLength
    expect(log_entry.level).to eq "info"
    expect(log_entry.category).to eq "cleanup"
    expect(log_entry.subject).to eq group
  end

  it "clears contact person from archived group when no role exists and creates log entry" do
    group.update_column(:archived_at, 1.day.ago)

    person.roles.destroy_all
    expect { subject.perform }
      .to change { group.reload.contact }.from(person).to(nil)
      .and change { HitobitoLogEntry.count }.by(1)

    log_entry = HitobitoLogEntry.last
    # rubocop:todo Layout/LineLength
    expect(log_entry.message).to eq "Contact person of Bottom One was removed, due to person not having any active member role in Bottom One"
    # rubocop:enable Layout/LineLength
    expect(log_entry.level).to eq "info"
    expect(log_entry.category).to eq "cleanup"
    expect(log_entry.subject).to eq group
  end

  it "does nothing when contact person does still have role" do
    expect { subject.perform }
      .to not_change { group.reload.contact }
      .and not_change { HitobitoLogEntry.count }
  end
end
