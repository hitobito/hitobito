# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Message::LetterWithInvoice do
  let(:invoice_attrs) {
    {
      'invoice_items_attributes' => {
        '1' =>{'name'=>'Mitgliedsbeitrag 2021', '_destroy' => 'false' }
      }
    }
  }

  it 'new record accepts invoice_attributes' do
    subject.mailing_list = mailing_lists(:leaders)
    subject.invoice_attributes = invoice_attrs
    expect(subject.invoice.invoice_items.first.name).to eq 'Mitgliedsbeitrag 2021'
  end

  it 'persisted record accepts updates to invoice_attributes' do
    message = messages(:with_invoice)
    message.update(invoice_attributes: invoice_attrs)
    expect(message.reload.invoice.invoice_items.first.name).to eq 'Mitgliedsbeitrag 2021'
  end

  it 'builds valid invoice_list' do
    message = messages(:with_invoice)
    expect(message.invoice_list).to be_valid
    message.save
    expect(message.invoice_list).to be_persisted
  end

  context 'invoice' do
    let(:recipient) { people(:bottom_member) }

    subject { messages(:with_invoice) }

    it '#invoice_for returns valid invoice' do
      invoice = subject.invoice_for(recipient)
      expect(invoice).to be_valid
      expect(invoice.recipient_address).to be_present
    end
  end

  context 'invoice items' do

    let(:letter) { messages(:with_invoice) }
    let(:invalid_invoice_item_attrs) { { 'name' => 'Invalid Item', 'count' => nil, 'unit_cost' => nil } }

    it 'validates invoice items' do
      letter.invoice_attributes['invoice_items_attributes'][2] = invalid_invoice_item_attrs
      expect(letter).not_to be_valid
    end

  end
end
