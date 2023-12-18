# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::BlockService do

  let(:person) { people(:top_leader) }
  subject(:block_service) { described_class.new(person) }
  let(:block_after_value) { nil }
  let(:warn_after_value) { nil }
  before { allow(Settings).to receive_message_chain(:people, :inactivity_block, :block_after).and_return(block_after_value) }
  before { allow(Settings).to receive_message_chain(:people, :inactivity_block, :warn_after).and_return(warn_after_value) }

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

  describe '::block_after' do
    subject(:block_after) { described_class.block_after }

    context 'with unset value' do
      let(:block_after_value) { nil }

      it 'returns nil' do
        expect(block_after).to be_nil
        expect(described_class.block?).to be_falsy
      end
    end

    context 'with string value' do
      let(:block_after_value) { '900' }

      it 'returns duration' do
        expect(block_after).to eq(15.minutes)
        expect(described_class.block?).to be_truthy
      end
    end

    context 'with value < warn_after' do
      let(:block_after_value) { '337' }
      let(:warn_after_value) { '1000' }

      it 'adds the periods' do
        expect(described_class.warn_after).to eq(1000.seconds)
        expect(described_class.block_after).to eq(1337.seconds)
      end
    end
  end

  describe '::warn_block_period' do
    subject(:warn_block_period) { described_class.warn_block_period }
    before { allow(Settings).to receive_message_chain(:people, :inactivity_block, :warn_after).and_return(warn_after_value) }
    before { allow(Settings).to receive_message_chain(:people, :inactivity_block, :block_after).and_return(block_after_value) }

    context 'with unset value' do
      let(:warn_after_value) { nil }

      it 'returns nil' do
        expect(warn_block_period).to be_nil
      end
    end

    context 'both values' do
      let(:warn_after_value) { 4.months }
      let(:block_after_value) { 6.months }

      it 'returns duration' do
        expect(warn_block_period).to eq(2.months)
      end
    end
  end

  describe '::warn_after' do
    subject(:warn_after) { described_class.warn_after }
    before { allow(Settings).to receive_message_chain(:people, :inactivity_block, :warn_after).and_return(warn_after_value) }

    context 'with unset value' do
      let(:warn_after_value) { nil }

      it 'returns nil' do
        expect(warn_after).to be_nil
        expect(described_class.warn?).to be_falsy
      end
    end

    context 'with string value' do
      let(:warn_after_value) { '900' }

      it 'returns duration' do
        expect(warn_after).to eq(15.minutes)
        expect(described_class.warn?).to be_truthy
      end
    end
  end

  describe '::block_scope' do
    subject(:block_scope) { described_class.block_scope }
    let(:person) { people(:bottom_member) }
    let(:block_after_value) { 6.months }
    let(:last_sign_in_at) { block_after_value&.+(3.months)&.ago }

    before do
      person.update(last_sign_in_at: last_sign_in_at)
    end

    context 'with inactive person' do
      it 'blocks the person' do
        expect(block_scope).to include(person)
      end
    end

    context 'with already blocked person' do
      before { block_service.block! }

      it 'ignores person' do
        expect(block_scope).not_to include(person)
      end
    end

    context 'with active person' do
      before { person.touch(:last_sign_in_at) }

      it 'ignores person' do
        expect(block_scope).not_to include(person)
      end
    end

    context 'with warning not sent' do
      before { person.update(inactivity_block_warning_sent_at: nil) }

      it 'includes person' do
        expect(block_scope).to include(person)
      end
    end

    context 'with never logged in' do
      let(:last_sign_in_at) { nil }

      it 'ignores person' do
        expect(block_scope).not_to include(person)
      end
    end

    context 'with no block_after set' do
      let(:inactivity_block_warning_sent_at) { nil }
      let(:block_after_value) { nil }

      it 'returns early' do
        expect(block_scope).to be_nil
      end
    end
  end

  describe '::warn_scope' do
    subject(:warn_scope) { described_class.warn_scope }
    let(:person) { people(:bottom_member) }
    let(:warn_after_value) { 6.months }
    let(:last_sign_in_at) { warn_after_value&.+(3.months)&.ago }

    before do
      person.update(last_sign_in_at: last_sign_in_at)
    end

    context 'with inactive person' do
      it 'includes the person' do
        expect(warn_scope).to include(person)
      end
    end

    context 'with already blocked person' do
      before { block_service.block! }

      it 'ignores person' do
        expect(warn_scope).not_to include(person)
      end
    end

    context 'with active person' do
      before { person.touch(:last_sign_in_at) }

      it 'ignores person' do
        expect(warn_scope).not_to include(person)
      end
    end

    context 'with warning already sent' do
      before { person.update(inactivity_block_warning_sent_at: 3.months.ago) }

      it 'ignores person' do
        expect(warn_scope).not_to include(person)
      end
    end

    context 'with never logged in' do
      let(:last_sign_in_at) { nil }

      it 'ignores person' do
        expect(warn_scope).not_to include(person)
      end
    end

    context 'with no warn_after set' do
      let(:warn_after_value) { nil }

      it 'returns early' do
        expect(warn_scope).to be_nil
      end
    end
  end
end
