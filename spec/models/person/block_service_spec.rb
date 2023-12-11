# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::BlockService do

  let(:person) { people(:top_leader) }
  subject(:block_service) { described_class.new(person) }

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
    before { allow(Settings).to receive_message_chain(:inactivity_block, :block_after).and_return(block_after_value) }

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
  end

  describe '::warn_after' do
    subject(:warn_after) { described_class.warn_after }
    before { allow(Settings).to receive_message_chain(:inactivity_block, :warn_after).and_return(warn_after_value) }

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
end
