# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.


require 'spec_helper'

describe MailingLists::BulkMail::DeliveryReportMessageJob do
  include MailingLists::ImapMailsSpecHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:mail_log) { MailLog.create!(mail_from: 'mr-sender@example.com') }
  let(:bulk_mail) { Message::BulkMail.create!(subject: 'Sommerlager', state: :finished, mailing_list: mailing_list, mail_log: mail_log) }

  subject { described_class.new(bulk_mail) }

  before do
    10.times do
      create_success_recipient_entry
    end

    create_failed_recipient_entry
  end

  it 'sends delivery report mail for given bulk mail' do
    Settings.email.list_domain = 'hitobito.example.com'

    envelope_sender = 'leaders@hitobito.example.com'
    delivery_report_to = 'mr-sender@example.com'

    expect_any_instance_of(DeliveryReportMailer)
      .to receive(:bulk_mail)
      .with(delivery_report_to,
            envelope_sender,
            'Sommerlager',
            10,
            instance_of(ActiveSupport::TimeWithZone),
            [['failed@example.com', 'failure is always an option!']])

    subject.perform
  end

  private

  def create_success_recipient_entry
    person = Fabricate(:person)
    MessageRecipient.create!(state: :sent,
                             message: bulk_mail,
                             email: person.email,
                             person: person)
  end

  def create_failed_recipient_entry
    MessageRecipient.create!(state: :failed,
                             message: bulk_mail,
                             email: 'failed@example.com',
                             error: 'failure is always an option!',
                             person: Fabricate(:person))
  end
end
