# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'csv'

describe Export::Tabular::Invoices::List do

  let(:group) { groups(:bottom_layer_one) }

  let(:list) { group.invoices }
  let(:data) { Export::Tabular::Invoices::List.csv(list) }
  let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

   its(:headers) do
     should == [
       'Titel', 'Nummer', 'Status', 'Referenz Nummer', 'Text', 'Empfänger E-Mail',
       'Empfänger Adresse', 'Verschickt am', 'Fällig am', 'Betrag',
       'MwSt.', 'Total inkl. MwSt.', 'Total bezahlt',
       'Kostenstellen', 'Konten', 'Zahlungseingänge'
     ]
   end

   it 'has 2 items' do
     expect(subject.size).to eq(2)
   end

   context 'first row' do

     subject { csv[0] }

     its(['Titel']) { should == 'Invoice' }
     its(['Nummer']) { should == invoices(:invoice).sequence_number }
     its(['Status']) { should == 'Entwurf' }
     its(['Referenz Nummer']) { should == invoices(:invoice).esr_number }
     its(['Betrag']) { should == '5.00' }
     its(['MwSt.']) { should == '0.35' }
     its(['Total inkl. MwSt.']) { should == '5.35' }
     its(['Total bezahlt']) { should == '0.00' }
     its(['Empfänger E-Mail']) { should == 'top_leader@example.com' }
     its(['Beschreibung']) { should == nil }
     its(['Empfänger Adresse']) { should == nil }
     its(['Verschickt am']) { should == nil }
     its(['Fällig am']) { should == nil }
   end

   context 'second row' do

     subject { csv[1] }
     let(:invoice ) { invoices(:sent) }

     its(['Titel']) { should == 'Sent' }
     its(['Nummer']) { should == invoice.sequence_number }
     its(['Status']) { should == 'per Mail versendet' }
     its(['Referenz Nummer']) { should == invoice.esr_number }
     its(['Verschickt am']) { should == I18n.l(invoice.sent_at) }
     its(['Fällig am']) { should == I18n.l(invoice.due_at) }
     its(['Betrag']) { should == '0.50' }
     its(['MwSt.']) { should == '0.00' }
     its(['Total inkl. MwSt.']) { should == '0.50' }
     its(['Total bezahlt']) { should == '0.00' }
     its(['Empfänger E-Mail']) { should == 'top_leader@example.com' }
     its(['Beschreibung']) { should == nil }
     its(['Empfänger Adresse']) { should == nil }
   end
end
