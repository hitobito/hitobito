# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::MessageJob do

  subject { Export::MessageJob.new(format, user.id, message.id, { filename: 'message_export' }) }

  let(:user) { people(:top_leader) }
  let(:person1) { create_person }
  let(:person2) { create_person }
  let(:person3) { create_person }
  let(:top_layer) { groups(:top_layer) }
  let(:filepath) { AsyncDownloadFile::DIRECTORY.join('message_export') }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  context 'creates a CSV-Export for letter with invoice' do
    let(:format) { :csv }

    let(:message) do
      Message::LetterWithInvoice
        .create!(mailing_list: mailing_lists(:leaders),
                 body: 'Lorem ipsum',
                 subject: 'A Sunny Day')
    end 

    before do
      create_invoice(person1)
      create_invoice(person2)
      create_invoice(person3)
      invoices(:invoice).destroy!
      invoices(:sent).destroy!
      message.update!(invoice_list_id: message.invoice_list.id)
      person3.destroy! # invoices from this person should not be included anymore
    end

    it 'and saves it' do
      subject.perform

      lines = File.readlines("#{filepath}.#{format}")
      expect(lines.size).to eq(9)
      expect(lines[0]).to match(/Referenz Nummer;Empfänger E-Mail;Empfänger Adresse;Referenz.*/)
      expect(lines[0].split(';').count).to match(21)
    end
  end

  private

  def create_invoice(recipient)
    invoice = invoices(:sent).dup
    invoice.recipient = recipient
    invoice.invoice_list_id = message.invoice_list.id
    invoice.invoice_items << invoice_items(:pins).dup
    invoice.save!
    invoice
  end

  def create_person
    person = Fabricate(:person_with_address)
    Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: person)
    person
  end

end
