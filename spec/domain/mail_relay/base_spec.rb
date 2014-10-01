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
        relay.receiver_from_received_header.should be_nil
      end
    end

    context 'regular' do
      let(:message) { regular }

      it 'returns receiver' do
        relay.receiver_from_received_header.should == 'zumkehr'
      end
    end

    context 'list' do
      let(:message) { list }

      it 'returns receiver' do
        relay.receiver_from_received_header.should == 'zumkehr'
      end
    end
  end

  describe '#envelope_receiver_name' do
    context 'regular' do
      let(:message) { regular }

      it 'returns receiver' do
        relay.envelope_receiver_name.should == 'zumkehr'
      end
    end
  end

  describe '#relay' do
    let(:message) { regular }

    subject { last_email }

    context 'without receivers' do
      before { relay.relay }

      it { should be_nil }
    end

    context 'with receivers' do
      let(:receivers) { %w(a@example.com b@example.com) }
      before do
        relay.stub(:receivers).and_return(receivers)
        relay.relay
      end

      it { should be_present }
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
      Mail.should_receive(:find_and_delete) do |options, &block|
        msgs = first ? [1, 2, 3, 4, 5] : [6, 7, 8]
        msgs.each { |m| block.call(m) }
        first = false
        msgs
      end.twice

      m = double
      m.stub(:relay)
      MailRelay::Base.stub(:new).and_return(m)
      MailRelay::Base.should_receive(:new).exactly(8).times

      MailRelay::Base.relay_current
    end

    it 'fails after one batch' do
      MailRelay::Base.retrieve_count = 5

      first = true

      msgs1 = (1..5).collect { |i| m = double; m.stub(:mark_for_delete=); m }
      msgs2 = (6..8).collect { |i| m = double; m.stub(:mark_for_delete=); m }

      Mail.should_receive(:find_and_delete) do |options, &block|
        msgs = first ? msgs1 : msgs2
        msgs.each { |m| block.call(m) }
        first = false
        msgs
      end

      m = double
      m.stub(:relay)
      MailRelay::Base.stub(:new).with(anything).and_return(m)
      MailRelay::Base.stub(:new).with(msgs1[2]).and_raise('failure!')
      MailRelay::Base.should_receive(:new).exactly(5).times

      expect { MailRelay::Base.relay_current }.to raise_error(MailRelay::Error)
    end
  end
end
