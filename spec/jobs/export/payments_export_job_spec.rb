# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::PaymentsExportJob do

  subject { described_class.new(format, user.id, payment_ids, filename: filename) }
  let(:filename) { AsyncDownloadFile.create_name('payments_export', user.id) }
  let(:file) { AsyncDownloadFile.from_filename(filename, format) }

  let(:user)         { people(:top_leader) }
  let(:payment_ids) do
    5.times.map do
        Payment.create(amount: 20,
                       payee_attributes: { person_name: Faker::Name.name,
                                           person_address: Faker::Address.street_address })
      end
  end

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }

    it 'and saves it' do
      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(6)
      expect(lines[0]).to match(/Id;Betrag;Eingangsdatum;Zahlungsreferenz;Transaktionsidentifikator;Status;Schuldner Name;Schuldner Adresse/)
      expect(lines[0].split(';').count).to match(8)
    end
  end

end
