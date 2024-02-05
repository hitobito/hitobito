# frozen_string_literal: true

#  Copyright (c) 2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'csv'

describe Export::Tabular::Payments::List do

  let(:list) do
    [
      Payment.create!(amount: 50,
                      reference: '000037680338900000000000021',
                      transaction_identifier: '0000376803389000000000000215020220805',
                      received_at: 1.year.ago,
                      invoice: invoices(:sent),
                      payee_attributes: {
                        person_name: 'Bob Foo',
                        person_address: 'Belpstrasse 37, 3007 Bern'
                      }),
      Payment.create!(amount: 80,
                      reference: '000053126034700000000000016',
                      transaction_identifier: '0000531260347000000000000168020220805',
                      received_at: 2.years.ago,
                      payee_attributes: {
                        person_name: 'Alice Foo',
                        person_address: 'Hönggerstrasse 65, 8037 Zürich'
                      })
    ]
  end

  let(:data) { Export::Tabular::Payments::List.csv(list) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), '') }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  its(:headers) do
    should == ['Id', 'Betrag', 'Eingangsdatum', 'Zahlungsreferenz', 'Transaktionsidentifikator',
               'Status', 'Schuldner Name', 'Schuldner Adresse']
  end

  it 'has 2 items' do
    expect(subject.size).to eq(2)
  end

  context 'first row with contact' do

    subject { csv[0] }
    let(:payment) { list[0] }

    its(['Id']) { should == payment.id.to_s }
    its(['Betrag']) { should == payment.amount.to_s }
    its(['Eingangsdatum']) { should == I18n.l(payment.received_at) }
    its(['Zahlungsreferenz']) { should == payment.reference }
    its(['Transaktionsidentifikator']) { should == payment.transaction_identifier }
    its(['Schuldner Name']) { should == 'Bob Foo' }
    its(['Schuldner Adresse']) { should == 'Belpstrasse 37, 3007 Bern' }
  end

  context 'second row' do

    let(:second_group) { groups(:bottom_group_one_one) }

    subject { csv[1] }
    let(:payment) { list[1] }

    its(['Id']) { should == payment.id.to_s }
    its(['Betrag']) { should == payment.amount.to_s }
    its(['Eingangsdatum']) { should == I18n.l(payment.received_at) }
    its(['Zahlungsreferenz']) { should == payment.reference }
    its(['Transaktionsidentifikator']) { should == payment.transaction_identifier }
    its(['Schuldner Name']) { should == 'Alice Foo' }
    its(['Schuldner Adresse']) { should == 'Hönggerstrasse 65, 8037 Zürich' }
  end
end
