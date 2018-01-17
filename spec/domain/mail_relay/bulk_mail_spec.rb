# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailRelay::BulkMail do

  let(:message)  { Mail.new(File.read(Rails.root.join('spec', 'fixtures', 'email', 'simple.eml'))) }
  let(:recipients) { 16.times.collect { Faker::Internet.email } }
  let(:envelope_sender) { 'mailing_list@example.hitobito.com' }
  let(:delivery_report_to) { 'author@example.hitobito.com' }
  let(:bulk_mail) { MailRelay::BulkMail.new(message, envelope_sender, delivery_report_to, recipients) }
  let(:failed_recipients) { bulk_mail.instance_variable_get(:@failed_recipients) }

  before do
    allow(bulk_mail)
      .to receive(:sleep)
      .with(5)
  end

  describe 'delivery error' do

    context 'at initial deliver' do

      it 'throws exception if smtp connection error' do
        expect(message)
          .to receive(:deliver)
          .and_raise(Net::OpenTimeout, 'execution expired')

        expect do
          bulk_mail.deliver
        end.to raise_error(Net::OpenTimeout)
      end

      it 'throws exception if smtp relaying denied' do
        expect(message)
          .to receive(:deliver)
          .and_raise(Net::SMTPFatalError, '550 5.7.1 <mail@recipient.com> Relaying denied')

        expect do
          bulk_mail.deliver
        end.to raise_error(Net::SMTPFatalError)
      end

    end

    context 'after previous successful deliver of recipients block' do

      before do
        # initial block deliver successful
        expect(message)
          .to receive(:deliver)

        # make sure report is sent
        expect(bulk_mail)
          .to receive(:delivery_report)
      end

      it 'retries delivery after 5mins' do
        # connection error at second block
        expect(message)
          .to receive(:deliver)
          .and_raise(Net::OpenTimeout, 'execution expired')

        expect(bulk_mail)
          .to receive(:sleep)
          .with(300)

        # successful delivery at second try
        expect(message)
          .to receive(:deliver)

        bulk_mail.deliver
        expect(bulk_mail.instance_variable_get(:@retry)).to eql(0)
        expect(failed_recipients.size).to eq(0)
      end

      it 'retries delivery a second time after 30mins' do
        # connection error at second block
        expect(message)
          .to receive(:deliver)
          .twice
          .and_raise(Net::OpenTimeout, 'execution expired')

        expect(bulk_mail)
          .to receive(:sleep)
          .with(300)

        expect(bulk_mail)
          .to receive(:sleep)
          .with(1800)

        # successful delivery at third try
        expect(message)
          .to receive(:deliver)

        bulk_mail.deliver
        expect(bulk_mail.instance_variable_get(:@retry)).to eql(0)
        expect(failed_recipients.size).to eq(0)
      end

      it 'cancels all remaining recipients if still unable to deliver at third try' do
        expect(message)
          .to receive(:deliver)
          .exactly(3)
          .times
          .and_raise(Net::OpenTimeout, 'execution expired')

        expect(bulk_mail)
          .to receive(:sleep)
          .with(300)

        expect(bulk_mail)
          .to receive(:sleep)
          .with(1800)

        bulk_mail.deliver
        expect(bulk_mail.instance_variable_get(:@abort)).to eql(true)
        expect(bulk_mail.instance_variable_get(:@retry)).to eql(2)
        expect(failed_recipients.first).to eq([recipients.last, 'execution expired'])
      end

    end

    context 'domain not found error' do

      let(:invalid_domain_email) { recipients[3] }
      let(:domain_not_found_error) { "450 4.1.2 #{invalid_domain_email}: Recipient address rejected: Domain not found" }

      it 'skips recipients with invalid mail domain' do
        expect(message)
          .to receive(:deliver)
          .and_raise(Net::SMTPServerBusy, domain_not_found_error)

        expect(message)
          .to receive(:deliver)
          .twice

        failed_entry = [invalid_domain_email, domain_not_found_error]

        expect_any_instance_of(DeliveryReportMailer)
          .to receive(:bulk_mail)
          .with(delivery_report_to, message, 15, instance_of(DateTime), [failed_entry])

        bulk_mail.deliver
        expect(failed_recipients.size).to eq(1)
        expect(failed_recipients.first).to eq(failed_entry)
      end

      it 'raises error if email cannot be extracted from smtp error message' do
        invalid_domain_not_found_error = "450 4.1.2 no email here: Recipient address rejected: Domain not found"

        expect(message)
          .to receive(:deliver)
          .and_raise(Net::SMTPServerBusy, invalid_domain_not_found_error)

        expect do
          bulk_mail.deliver
        end.to raise_error(Net::SMTPServerBusy, invalid_domain_not_found_error)
      end

    end

    context 'bulk send' do

      let(:recipients) { 42.times.collect { Faker::Internet.email } }

      it 'sends mail to recipients in blocks' do

        expect(message)
          .to receive(:deliver)
          .exactly(3)
          .times

        expect(bulk_mail)
          .to receive(:sleep)
          .with(5)
          .exactly(2)
          .times

        expect_any_instance_of(DeliveryReportMailer)
          .to receive(:bulk_mail)
          .with(delivery_report_to, message, 42, instance_of(DateTime), [])

        bulk_mail.deliver
        expect(failed_recipients.size).to eq(0)
        succeeded_recipients = bulk_mail.instance_variable_get(:@succeeded_recipients)
        expect(succeeded_recipients).to eq(recipients)
      end

    end


  end 

end
