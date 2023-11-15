# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe People::CreateRolesJob do
  let(:person) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:role_type) { Group::TopGroup::Member.sti_name }
  let(:tomorrow) { Time.zone.tomorrow }

  subject(:job) { described_class.new }

  def create_future_role(attrs = {})
    defaults = { person: person, group: top_group, convert_to: role_type }
    Fabricate(:future_role, defaults.merge(attrs))
  end

  it 'noops and reschedules if no future role exists' do
    expect { job.perform }.to not_change { person.roles.count }
      .and change { Delayed::Job.count }.by(1)
    expect(Delayed::Job.last.run_at).to eq 1.hour.from_now.beginning_of_hour
  end

  it 'noops if role is scheduled for tomorrow' do
    create_future_role(convert_on: Time.zone.tomorrow)
    expect { job.perform }.to not_change { person.roles.where(type: role_type).count }
      .and not_change { person.roles.where(type: FutureRole.sti_name).count }
  end

  it 'destroys and creates role if scheduled for today' do
    create_future_role(convert_on: Time.zone.today)
    expect { job.perform }.to change { person.roles.where(type: role_type).count }.by(1)
      .and change { person.roles.where(type: FutureRole.sti_name).count }.by(-1)
  end

  it 'destroys and creates role even if person is invalid' do
    person.update_columns(first_name: nil, last_name: nil, email: nil)
    expect(person).not_to be_valid
    create_future_role(convert_on: Time.zone.today)
    expect { job.perform }.to change { person.roles.where(type: role_type).count }.by(1)
      .and change { person.roles.where(type: FutureRole.sti_name).count }.by(-1)
  end

  it 'destroys and creates multiples' do
    create_future_role(convert_on: Time.zone.today)
    create_future_role(convert_on: Time.zone.today, person: people(:top_leader))
    expect { job.perform }.to change { Role.where(type: role_type).count }.by(2)
      .and change { Role.where(type: FutureRole.sti_name).count }.by(-2)
  end

  it 'logs errors and continues' do
    role = create_future_role(convert_on: Time.zone.tomorrow)
    create_future_role(convert_on: Time.zone.tomorrow, person: people(:top_leader))
    allow_any_instance_of(FutureRole).to receive(:convert!).and_wrap_original do |m|
      raise 'ouch' if m.receiver.person == person
      m.call
    end
    expect(Raven).to receive(:capture_exception).with(described_class::Error.new("ouch - FutureRole(#{role.id})"))

    expect do
      travel_to(Time.zone.tomorrow) { job.perform  }
    end.to change { Role.where(type: role_type).count }.by(1)
      .and change { Role.where(type: FutureRole.sti_name).count }.by(-1)
  end
end
