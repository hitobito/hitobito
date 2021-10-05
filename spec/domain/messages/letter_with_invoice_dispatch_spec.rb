# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::LetterWithInvoiceDispatch do
  let(:message)    { messages(:with_invoice) }
  let(:top_leader) { people(:top_leader) }
  let(:recipient_entries) { message.message_recipients }

  before do
    Subscription.create!(mailing_list: mailing_lists(:leaders),
                         subscriber: groups(:top_group),
                         role_types: [Group::TopGroup::Leader])
    top_leader.update!(address: 'Fantasia 42', zip_code: '4242', town: 'Melmac')
  end

  subject { described_class.new(message) }

  it 'updates message invoice_list and invoices' do
    subject.run
    expect(message.reload.success_count).to eq 1
    expect(message.reload.invoice_list).to be_present
  end

  it 'creates invoice_list and invoices' do
    expect { subject.run }.to change { InvoiceList.count }.by(1)

    expect(recipient_entries.count).to eq(1)
    expect(message.invoice_list.reload.invoices).to have(1).item
    expect(message.invoice_list.recipients_processed).to eq 1
    expect(message.invoice_list.invalid_recipient_ids).to eq []
  end

  it 'creates and issues invoice' do
    expect { subject.run }.to change { Invoice.count }.by(1)

    invoice = message.invoice_list.reload.invoices.first
    expect(invoice.state).to eq 'issued'
    expect(invoice.title).to eq message.subject
    expect(invoice.invoice_items).to have(1).item
  end

  it 'tracks error during invoice creation' do
    expect_any_instance_of(Invoice).to receive(:save).and_return(false)
    expect { subject.run }.not_to change { Invoice.count }
    expect(message.reload.success_count).to eq 0
    expect(message.reload.failed_count).to eq 1
    expect(message.invoice_list.recipients_processed).to eq 0
    expect(message.invoice_list.invalid_recipient_ids).to eq [top_leader.id]
  end
end
