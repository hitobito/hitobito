# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::BlockService do
  before do
    # we need to clear the class instance variables as they get populated based on
    # the settings values and are cached between test runs while we might mock the
    # settings values with different values
    [:@warn_after, :@block_after].each do |ivar|
      described_class.instance_variable_set(ivar, nil)
    end
  end

  let(:person) { people(:top_leader) }
  subject(:block_service) { described_class.new(person) }
  let(:block_after_value) { nil }
  let(:warn_after_value) { nil }
  before { allow(Settings.people.inactivity_block).to receive(:block_after).and_return(block_after_value) }
  before { allow(Settings.people.inactivity_block).to receive(:warn_after).and_return(warn_after_value) }

  describe '#block!' do
    subject(:block!) { block_service.block! }

    it 'sets the blocked_at attribute to the current date' do
      expect(block!).to be_truthy
      expect(person.blocked_at).to be > 1.minute.ago
    end

    it 'logs a message with paper_trail' do
      expect { block! }.to change { PaperTrail::Version.count }.by(1)
    end
  end

  describe '#unblock!' do
    subject(:unblock!) { block_service.unblock! }

    it 'sets the blocked_at attribute to the current date' do
      expect(unblock!).to be_truthy
      expect(person.blocked_at).to be_nil
    end

    it 'logs a message with paper_trail' do
      expect { unblock! }.to change { PaperTrail::Version.count }.by(1)
    end
  end

  describe '#inactivity_warning!' do
    subject(:inactivity_warning!) { block_service.inactivity_warning! }

    it 'sends the activity warning mail' do
      expect(Person::InactivityBlockMailer).to receive(:inactivity_block_warning).and_call_original
      expect(inactivity_warning!).to be_truthy
    end

    it 'sets the inactivity_block_warning_sent_at attribute' do
      inactivity_warning!
      expect(person.inactivity_block_warning_sent_at).to be > 1.minute.ago
    end
  end

  [:warn_after, :block_after].each do |method|
    context "::#{method}" do
      it 'returns nil if settings value is blank' do
        allow(Settings.people.inactivity_block).to receive(method).and_return(nil)
        expect(Person::BlockService.send(method)).to be_nil
      end

      it 'returns parsed duration if settings value is set' do
        allow(Settings.people.inactivity_block).to receive(method).and_return('P1D')
        expect(Person::BlockService.send(method)).to eq(1.day)
      end

      it 'raises if settings value has wrong format' do
        allow(Settings.people.inactivity_block).to receive(method).and_return(42)
        expect { Person::BlockService.send(method) }.
          to raise_error(/Settings.people.inactivity_block.#{method} must be a duration in ISO 8601 format/)

        allow(Settings.people.inactivity_block).to receive(method).and_return('7 days')
        expect { Person::BlockService.send(method) }.
          to raise_error /#{method} must be a duration in ISO 8601 format, but is/
      end
    end
  end

  context '::warn?' do
    it 'returns true if warn_after is set' do
      allow(described_class).to receive(:warn_after).and_return(1.day)
      expect(described_class.warn?).to eq true
    end

    it 'returns false if warn_after is not set' do
      allow(described_class).to receive(:warn_after).and_return(nil)
      expect(described_class.warn?).to eq false
    end
  end

  context '::block?' do
    it 'returns true if block_after is set' do
      allow(described_class).to receive(:block_after).and_return(1.day)
      expect(described_class.block?).to eq true
    end

    it 'returns false if block_after is not set' do
      allow(described_class).to receive(:block_after).and_return(nil)
      expect(described_class.block?).to eq false
    end
  end

  context '::block_scope' do
    before do
      allow(Settings.people.inactivity_block).to receive(:block_after).and_return("P10D")
    end

    it 'returns empty scope if block? is false' do
      allow(described_class).to receive(:block?).and_return(false)

      expect(described_class.block_scope).to eq Person.none
    end

    it 'includes person with warning sent_at > block_after.ago' do
      person.update!(inactivity_block_warning_sent_at: 11.days.ago)

      expect(described_class.block_scope).to include person
    end

    it 'excludes person with warning sent_at < block_after' do
      person.update!(inactivity_block_warning_sent_at: 9.days.ago)

      expect(described_class.block_scope).not_to include person
    end

    it 'excludes person with warning sent_at=nil' do
      person.update!(inactivity_block_warning_sent_at: nil)

      expect(described_class.block_scope).not_to include person
    end

    it 'excludes blocked person' do
      person.update!(inactivity_block_warning_sent_at: 11.days.ago, blocked_at: 1.days.ago)

      expect(described_class.block_scope).not_to include person
    end
  end

  context '::warn_scope' do
    before do
      allow(Settings.people.inactivity_block).to receive(:warn_after).and_return("P10D")
    end

    it 'returns empty scope if warn? is false' do
      allow(described_class).to receive(:warn?).and_return(false)

      expect(described_class.warn_scope).to eq Person.none
    end

    it 'includes person with last_sign_in_at > warn_after.ago' do
      person.update!(last_sign_in_at: 11.days.ago)

      expect(described_class.warn_scope).to include person
    end

    it 'excludes person with last_sign_in_at < warn_after.ago' do
      person.update!(last_sign_in_at: 9.days.ago)

      expect(described_class.warn_scope).not_to include person
    end

    it 'excludes person with last_sign_in_at=nil' do
      person.update!(last_sign_in_at: nil)

      expect(described_class.warn_scope).not_to include person
    end

    it 'excludes blocked person' do
      person.update!(last_sign_in_at: 11.days.ago, blocked_at: 1.days.ago)

      expect(described_class.warn_scope).not_to include person
    end

    it 'excludes person with warning sent_at' do
      person.update!(last_sign_in_at: 11.days.ago, inactivity_block_warning_sent_at: 1.days.ago)

      expect(described_class.warn_scope).not_to include person
    end
  end

  describe '::block_within_scope' do
  subject(:block_within_scope) { described_class.block_within_scope! }
    let(:inactivity_block_warning_sent_at) { block_after_value&.+(3.months)&.ago }

    before do
      allow(described_class).to receive(:block_after).and_return(block_after_value)
      person.update(inactivity_block_warning_sent_at: inactivity_block_warning_sent_at)
    end

    context "with no block_after set" do
      before { expect(described_class).not_to receive(:new) }
      let(:block_after_value) { nil }

      it { expect(block_within_scope).to be_falsy }
    end

    context "with block_after set" do
      let(:block_after_value) { 1.months }
      let(:block_service) { double("BlockService") }
      before do
        expect(described_class).to receive(:new).with(person).and_return(block_service)
        expect(block_service).to receive(:block!)
      end

      it { expect(block_within_scope).to be_truthy }
    end
  end

  describe '::warn_within_scope' do
    subject(:warn_within_scope) { described_class.warn_within_scope! }
    let(:last_sign_in_at) { warn_after_value&.+(3.months)&.ago }

    before do
      allow(described_class).to receive(:warn_after).and_return(warn_after_value)
      person.update(last_sign_in_at: last_sign_in_at)
    end

    context "with no warn_after set" do
      let(:warn_after_value) { nil }
      it { expect(warn_within_scope).to be_falsy }
      it { expect(described_class).not_to receive(:new) }
    end

    context "with warn_after set" do
      let(:warn_after_value) { 6.months }
      let(:block_service) { double("BlockService") }

      before do
        expect(described_class).to receive(:new).with(person).and_return(block_service)
        expect(block_service).to receive(:inactivity_warning!)
      end

      it { expect(warn_within_scope).to be_truthy }
    end
  end

  context '::inactivity_block_interval_placeholders' do
    it 'returns placeholders for warn_after and block_after in days' do
      allow(described_class).to receive(:warn_after).and_return(10.days)
      allow(described_class).to receive(:block_after).and_return(3.5.days)

      expect(described_class.inactivity_block_interval_placeholders).to eq(
                                                                          'warn-after-days' => '10',
                                                                          'block-after-days' => '3'
                                                                        )
    end
  end
end
