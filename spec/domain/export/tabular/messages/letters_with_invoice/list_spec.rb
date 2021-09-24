# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Tabular::Messages::LettersWithInvoice::List do
  let(:invoices) { double('invoices', map: [], first: nil) }

  subject { described_class.new(invoices) }

  context 'used labels' do
    its(:attributes) do
      should == [:esr_number, :recipient_email, :recipient_address, :reference, :total,
                 :id, :first_name, :last_name, :company_name, :company, :email, :address,
                 :zip_code, :town, :country, :gender, :birthday, :salutation, :title,
                 :correspondence_language, :household_key]
    end

    its(:labels) do
      should == ['Referenz Nummer', 'Empfänger E-Mail', 'Empfänger Adresse', 'Referenz',
                 'Total inkl. MwSt.', 'Id', 'Vorname', 'Nachname', 'Firmenname', 'Firma',
                 'Haupt-E-Mail', 'Adresse', 'PLZ', 'Ort', 'Land', 'Geschlecht',
                 'Geburtstag', 'Anrede', 'Titel', 'Korrespondenzsprache', 'Haushalts-ID']
    end
  end
end
