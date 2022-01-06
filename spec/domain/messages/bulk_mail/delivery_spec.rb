# encoding: utf-8
# frozen_string_literal: true

# Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMail::Delivery do
  let(:mail_factory) { double }
  let(:retries) { 2 }
  let(:emails) { %w(first@example.com second@example.com) }
  let(:delivery) { described_class.new(mail_factory, emails, retries) }

  def ok_mail
    mail = double
    expect(mail).to receive(:deliver)
    mail
  end

  def error_mail(message)
    mail = double
    expect(mail).to receive(:deliver).and_raise("Recipient address rejected #{message}")
    mail
  end

  def exception_mail

    mail
  end

  context 'without errors' do
    context 'successful delivery' do
      it '#deliver' do
        expect(mail_factory).to receive(:to).once.ordered.with(emails).and_return(ok_mail)

        delivery.deliver
        expect(delivery.succeeded).to eq(emails)
        expect(delivery.failed).to eq([])
      end
    end

    context 'failed delivery' do
      it '#deliver' do
        expect(mail_factory).to receive(:to)
          .once
          .ordered
          .with(emails)
          .and_return(error_mail('second@example.com'))

        expect(mail_factory).to receive(:to)
          .once
          .ordered
          .with(%w(first@example.com))
          .and_return(ok_mail)

        delivery.deliver
        expect(delivery.succeeded).to eq(%w(first@example.com))
        expect(delivery.failed).to eq(%w(second@example.com))
      end
    end

    context 'too many retries' do
        let(:retries) { 1 }

        it '#deliver' do
          expect(mail_factory).to receive(:to)
            .once
            .ordered
            .with(emails)
            .and_return(error_mail('second@example.com'))

          expect do
            delivery.deliver
          end.to raise_error(Messages::BulkMail::Delivery::RetriesExceeded)
        end
      end
  end

  context 'with errors' do
    it '#deliver' do
      mail = double
      expect(mail).to receive(:deliver).and_raise('Some unexpected exception')

      expect(mail_factory).to receive(:to)
        .once
        .ordered
        .with(emails)
        .and_return(mail)

      expect do
        delivery.deliver
      end.to raise_error('Some unexpected exception')
    end
  end
end
