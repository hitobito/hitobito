# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Tabular::Invoices::Row do

  let(:invoice) { invoices(:invoice) }
  subject { described_class.new(invoice) }


  it 'matche values' do
    values = Export::Tabular::Invoices::List::INCLUDED_ATTRS.collect { |x| [x, subject.fetch(x)]   }.to_h
    expect(values).to match(
      {"title"=>"Invoice",
       "sequence_number"=>"376803389-2",
       "state"=>"Entwurf",
       "esr_number"=>"00 00376 80338 90000 00000 00021",
       "description"=>nil,
       "recipient_email"=>"top_leader@example.com",
       "recipient_address"=>nil,
       "sent_at"=>nil,
       "due_at"=>nil,
       "cost"=>"5.00",
       "vat"=>"0.35",
       "total"=>"5.35",
       "amount_paid"=>"0.00"}
    )
  end

  it 'does not include separators for large numbers' do
    invoice.total = 10_123.12
    expect(subject.total).to eq '10123.12'
  end

  it 'does add precision for whole numbers' do
    invoice.total = 10
    expect(subject.total).to eq '10.00'
  end

end

