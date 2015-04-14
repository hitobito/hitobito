# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailRelay::Base do

  let(:simple)  { Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'simple.eml'))) }
  let(:regular) { Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'regular.eml'))) }
  let(:list)    { Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'list.eml'))) }

  let(:relay) { MailRelay::Base.new(message) }

  describe '#receiver_from_received_header' do
    context 'simple' do
      let(:message) { simple }

      it 'returns nil' do
        expect(relay.receiver_from_received_header).to be_nil
      end
    end

    context 'regular' do
      let(:message) { regular }

      it 'returns receiver' do
        expect(relay.receiver_from_received_header).to eq('zumkehr')
      end
    end

    context 'list' do
      let(:message) { list }

      it 'returns receiver' do
        expect(relay.receiver_from_received_header).to eq('zumkehr')
      end
    end
  end

  describe '#envelope_receiver_name' do
    context 'regular' do
      let(:message) { regular }

      it 'returns receiver' do
        expect(relay.envelope_receiver_name).to eq('zumkehr')
      end
    end
  end

  describe '#relay' do
    let(:message) { regular }

    subject { last_email }

    context 'without receivers' do
      before { relay.relay }

      it { is_expected.to be_nil }
    end

    context 'with receivers' do
      let(:receivers) { %w(a@example.com b@example.com) }
      before do
        allow(relay).to receive(:receivers).and_return(receivers)
        relay.relay
      end

      it { is_expected.to be_present }
      its(:smtp_envelope_to) { should == receivers }
      its(:to) { should == ['zumkehr@puzzle.ch'] }
      its(:from) { should == ['animation@jublaluzern.ch'] }

      context 'with internationalized domain names' do
        let(:receivers) { %w(a@exämple.com b@example.com) }

        its(:smtp_envelope_to) { should == %w(a@xn--exmple-cua.com b@example.com) }
      end
    end
  end

  describe '.relay_current' do
    it 'processes all mails' do
      MailRelay::Base.retrieve_count = 5

      first = true
      expect(Mail).to receive(:find_and_delete) { |options, &block|
        msgs = first ? [1, 2, 3, 4, 5] : [6, 7, 8]
        msgs.each { |m| block.call(m) }
        first = false
        msgs
      }.twice

      m = double
      allow(m).to receive(:relay)
      allow(MailRelay::Base).to receive(:new).and_return(m)
      expect(MailRelay::Base).to receive(:new).exactly(8).times

      MailRelay::Base.relay_current
    end

    it 'fails after one batch' do
      MailRelay::Base.retrieve_count = 5

      first = true

      msgs1 = (1..5).collect { |i| m = double; allow(m).to receive(:mark_for_delete=); m }
      msgs2 = (6..8).collect { |i| m = double; allow(m).to receive(:mark_for_delete=); m }

      expect(Mail).to receive(:find_and_delete) do |options, &block|
        msgs = first ? msgs1 : msgs2
        msgs.each { |m| block.call(m) }
        first = false
        msgs
      end

      m = double
      allow(m).to receive(:relay)
      allow(MailRelay::Base).to receive(:new).with(anything).and_return(m)
      allow(MailRelay::Base).to receive(:new).with(msgs1[2]).and_raise('failure!')
      expect(MailRelay::Base).to receive(:new).exactly(5).times

      expect { MailRelay::Base.relay_current }.to raise_error(MailRelay::Error)
    end
  end
end
