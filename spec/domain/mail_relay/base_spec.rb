# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailRelay::Base do

  let(:mails)                  { Rails.root.join('spec', 'fixtures', 'email') }
  let(:simple)                 { Mail.new(mails.join('simple.eml').read) }
  let(:regular)                { Mail.new(mails.join('regular.eml').read) }
  let(:list)                   { Mail.new(mails.join('list.eml').read) }
  let(:multiple)               { Mail.new(mails.join('multiple.eml').read) }
  let(:multiple_both)          { Mail.new(mails.join('multiple_both.eml').read) }
  let(:multiple_x_original_to) { Mail.new(mails.join('multiple_x_original_to.eml').read) }

  let(:relay) { MailRelay::Base.new(message) }

  before do
    # we do not have custom content for report loaded in test env
    allow_any_instance_of(DeliveryReportMailer).
      to receive(:bulk_mail)
  end

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
    context 'multiple' do
      let(:message) { multiple }

      it 'returns single receiver' do
        expect(relay.envelope_receiver_name).to eq('kalei.kontakt')
      end
    end
    context 'multiple both' do
      let(:message) { multiple_both }

      it 'returns single receiver' do
        expect(relay.envelope_receiver_name).to eq('kalei.kontakt')
      end
    end
    context 'multiple x-original-to' do
      let(:message) { multiple_x_original_to }

      it 'returns single receiver' do
        expect(relay.envelope_receiver_name).to eq('teststatus.zha0')
      end
    end
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

    it 'creates log entry for mail with rejected sender' do
      expect(Mail).to receive(:find_and_delete) do |options, &block|
        block.call(simple)
        [simple]
      end

      expect_any_instance_of(MailRelay::Base).to receive(:sender_allowed?).and_return(false)

      expect do
        MailRelay::Base.relay_current
      end.to change { MailLog.count }.by(1)

      mail_log = MailLog.find_by(mail_hash: 'e63f22f5d97d8030174951265555794f')
      expect(mail_log.message.subject).to eq(simple.subject)
      expect(mail_log.message.state).to eq('failed')
      expect(mail_log.message.sent_at).to eq(mail_log.updated_at)
      expect(mail_log.mail_from).to eq(simple.from.first)
      expect(mail_log.status).to eq('sender_rejected')
    end

    it 'creates log entry for mail with unknown recipient' do
      expect(Mail).to receive(:find_and_delete) do |options, &block|
        block.call(simple)
        [simple]
      end

      expect_any_instance_of(MailRelay::Base).to receive(:relay_address?).and_return(false)

      expect do
        MailRelay::Base.relay_current
      end.to change { MailLog.count }.by(1)

      mail_log = MailLog.find_by(mail_hash: 'e63f22f5d97d8030174951265555794f')
      expect(mail_log.message.subject).to eq(simple.subject)
      expect(mail_log.message.state).to eq('failed')
      expect(mail_log.message.sent_at).to eq(mail_log.updated_at)
      expect(mail_log.mail_from).to eq(simple.from.first)
      expect(mail_log.status).to eq('unkown_recipient')
    end

    it 'skips already processed mail and sends airbrake notification' do
      MailLog.build(simple).save!

      expect(Mail).to receive(:find_and_delete) do |options, &block|
        block.call(simple)
        [simple]
      end

      expect(Airbrake).to receive(:notify) do |exception|
        expect(exception.message).to match(
          /Mail with subject 'Re: Jubla Gruppen' has already been processed before and is skipped/)
        expect(exception.message).to match(
          /e63f22f5d97d8030174951265555794f$/)
      end

      MailRelay::Base.relay_current
    end

    it 'skips already processed mail, does not sends airbrake notification if mail_log is completed' do
      log = MailLog.build(simple)
      log.update(status: 2)
      log.save!

      expect(Mail).to receive(:find_and_delete) do |options, &block|
        block.call(simple)
        [simple]
      end

      expect(Airbrake).not_to receive(:notify) do |exception|
        expect(exception.message).to match(
          /Mail with subject 'Re: Jubla Gruppen' has already been processed before and is skipped/)
        expect(exception.message).to match(
          /e63f22f5d97d8030174951265555794f$/)
      end

      MailRelay::Base.relay_current
    end


    it 'creates mail log entry for sent bulk mail' do
      expect(Mail).to receive(:find_and_delete) do |options, &block|
        block.call(simple)
        [simple]
      end

      expect do
        MailRelay::Base.relay_current
      end.to change { MailLog.count }.by(1)

      mail_log = MailLog.find_by(mail_hash: 'e63f22f5d97d8030174951265555794f')
      expect(mail_log.message.subject).to eq(simple.subject)
      expect(mail_log.message.state).to eq('finished')
      expect(mail_log.message.sent_at).to eq(mail_log.updated_at)
      expect(mail_log.mail_from).to eq(simple.from.first)
      expect(mail_log.status).to eq('completed')
    end

    it 'creates mail log entry for mail with emoji in subject' do
      emoji_subject = "⛴ Unvergessliche Erlebnisse"
      simple.subject = emoji_subject
      expect(Mail).to receive(:find_and_delete) do |options, &block|
        block.call(simple)
        [simple]
      end

      expect do
        MailRelay::Base.relay_current
      end.to change { MailLog.count }.by(1)

      mail_log = MailLog.find_by(mail_hash: 'e63f22f5d97d8030174951265555794f')
      expect(mail_log.message.subject).to eq("⛴ Unvergessliche Erlebnisse")
      expect(mail_log.mail_from).to eq(simple.from.first)
      expect(mail_log.status).to eq('completed')
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

    it 'logs EOF Error without creating MailLog' do
      expect(Mail).to receive(:find_and_delete) do |options, &block|
        fail EOFError.new('ouch')
      end

      expect do
        MailRelay::Base.relay_current
      end.not_to change { MailLog.count }

      mail_log = MailLog.find_by(mail_hash: 'e63f22f5d97d8030174951265555794f')
      expect(mail_log).not_to be_present
    end
  end
end
