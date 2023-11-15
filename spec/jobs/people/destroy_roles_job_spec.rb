# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe People::DestroyRolesJob do

  let(:person) { role.person }
  let(:role) { roles(:bottom_member) }
  subject(:job) { described_class.new }

  it 'noops if not scheduled' do
    expect { job.perform }.to not_change { person.roles.count }
      .and change { Delayed::Job.count }.by(1)
    expect(Delayed::Job.last.run_at).to eq 1.hour.from_now.beginning_of_hour
  end

  it 'noops if not scheduled in the future' do
    role.update!(delete_on: Time.zone.tomorrow.to_date)
    expect { job.perform }.to not_change { person.roles.count }
  end

  it 'destroys role if scheduled today' do
    role.update!(delete_on: Time.zone.today.to_date)
    expect { job.perform }.to change { person.roles.count }.by(-1)
  end

  it 'destroys even if person is invalid' do
    role.update!(delete_on: Time.zone.today.to_date)
    person.update_columns(first_name: nil, last_name: nil, email: nil)
    expect(person).not_to be_valid
    expect { job.perform }.to change { person.roles.count }.by(-1)
  end

  it 'destroys role if scheduled yesterday' do
    role.update!(created_at: 3.days.ago, delete_on: Time.zone.yesterday.to_date)
    expect { job.perform }.to change { person.roles.count }.by(-1)
  end

  it 'destroys all scheduled roles' do
    role.update!(created_at: 3.days.ago, delete_on: Time.zone.yesterday.to_date)
    roles(:top_leader).update!(delete_on: Time.zone.today.to_date)
    expect { job.perform }.to change { Role.count }.by(-2)
  end

  it 'logs errors and continues' do
    role.update!(created_at: 3.days.ago, delete_on: Time.zone.yesterday.to_date)
    roles(:top_leader).update!(delete_on: Time.zone.today.to_date)
    allow_any_instance_of(Role).to receive(:destroy!).and_wrap_original do |m|
      raise 'ouch' if m.receiver == role
      m.call
    end
    expect(Raven).to receive(:capture_exception).with(described_class::Error.new("ouch - Group::BottomLayer::Member(#{role.id})"))

    expect { job.perform }.to change { Role.count }.by(-1)
  end
end

