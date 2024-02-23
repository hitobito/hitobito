# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Roles::Termination do
  context 'validations' do
    context 'role' do
      it 'is invalid without role' do
        subject.role = nil
        expect(subject).to have(1).error_on(:role)
      end

      it 'is invalid with not terminatable role' do
        subject.role = double('Role', terminatable?: false)
        expect(subject).to have(1).error_on(:role)
        expect(subject.errors[:role]).to include('ist nicht kündbar')
      end

      it 'is valid with role' do
        subject.role = double('Role', terminatable?: true)
        expect(subject).to have(:no).errors_on(:role)
      end
    end

    context 'terminate_on' do
      it 'is invalid without terminate_on' do
        subject.terminate_on = nil
        expect(subject).to have(1).error_on(:terminate_on)
      end

      it 'is invalid with terminate_on before minimum_termination_date' do
        subject.terminate_on = Time.zone.today
        expect(subject).to have(1).error_on(:terminate_on)
        expect(subject.errors[:terminate_on]).to include('muss in der Zukunft liegen')
      end

      it 'is invalid with terminate_on after maximum_termination_date' do
        subject.terminate_on = 2.years.from_now.to_date
        expect(subject).to have(1).error_on(:terminate_on)
        expect(subject.errors[:terminate_on]).to include(/darf nicht nach dem \d+\.\d+\.\d+ sein/)
      end

      it 'is valid with terminate_on in range' do
        subject.terminate_on = 1.month.from_now.to_date
        expect(subject).to have(:no).errors_on(:terminate_on)
      end
    end
  end

  context 'call' do
    let(:role) { roles(:bottom_member) }
    let(:terminate_on) { 1.month.from_now.to_date }

    let(:subject) { described_class.new(role: role, terminate_on: terminate_on) }

    it 'when valid terminates role and returns true' do
      allow(subject).to receive(:valid?).and_return(true)

      expect do
        expect(subject.call).to eq true
      end.
        to change { role.reload.terminated? }.from(false).to(true).
        and change { role.reload.delete_on }.from(nil).to(terminate_on)
    end

    it 'when invalid does not terminate role and returns false' do
      allow(subject).to receive(:valid?).and_return(false)

      expect do
        expect(subject.call).to eq false
      end.
        to not_change { role.reload.terminated? }.from(false).
        and not_change { role.reload.delete_on }.from(nil)
    end
  end

  it '#main_person returns role.person' do
    subject.role = roles(:bottom_member)
    expect(subject.main_person).to eq subject.role.person
  end

  it '#affected_people is empty' do
    subject.role = roles(:bottom_member)
    expect(subject.affected_people).to be_empty
  end
end
