# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceConfig do
  let(:group)          { groups(:top_layer) }
  let(:person)         { people(:top_leader) }
  let(:other_person)   { people(:bottom_member) }
  let(:invoice_config) { group.invoice_config }

  describe 'payment_slip dependent validations' do
    subject { Fabricate(Group::BottomLayer.sti_name, id: 1).reload.invoice_config }

    it 'ch_es' do
      subject.payment_slip = 'ch_es'
      expect(subject).not_to be_valid
      expect(subject.errors.keys).to eq [:payee, :iban]
    end

    it 'ch_esr' do
      subject.payment_slip = 'ch_esr'
      expect(subject).not_to be_valid
      expect(subject.errors.keys).to eq [:payee, :participant_number]
    end

    it 'ch_bes' do
      subject.payment_slip = 'ch_bes'
      expect(subject).not_to be_valid
      expect(subject.errors.keys).to eq [:payee, :beneficiary, :iban]
    end

    it 'ch_besr' do
      subject.payment_slip = 'ch_besr'
      expect(subject).not_to be_valid
      expect(subject.errors.keys).to eq [:payee, :beneficiary, :participant_number, :participant_number_internal]
    end

    it 'no_ps' do
      subject.payment_slip = 'no_ps'
      expect(subject).not_to be_valid
      expect(subject.errors.keys).to eq [:payee, :iban]
    end

    it 'qr' do
      subject.payment_slip = 'qr'
      expect(subject).not_to be_valid
      expect(subject.errors.keys).to eq [:payee, :iban]
    end
  end

  it 'validates correct payee format'

  it 'validates correct iban format' do
    invoice_config.update(iban: 'wrong format')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include('IBAN ist nicht gültig')
  end

  it 'validates correct account_number format if post payment' do
    invoice_config.update(account_number: 'wrong format')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include('Kontonummer ist nicht gültig')
  end

  it 'does not validate account_number if bank payment' do
    invoice_config.update(payment_slip: 'ch_bes')

    invoice_config.update(account_number: 'invalid-number')
    expect(invoice_config).to be_valid
  end

  it 'validates presence of payee' do
    invoice_config.update(payee: '')

    expect(invoice_config).not_to be_valid
  end

  it 'validates wordwrap of payee if bank payment' do
    invoice_config.update(payee: "line1 \n line2 \n \line 3", payment_slip: 'ch_bes')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).
      to include('Einzahlung für darf höchstens 2 Zeilen enthalten')
  end

  it 'validates account_number check digit if post payment' do
    # incorrect check digit
    invoice_config.update(account_number: '12-123-1')

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include(/Inkorrekte Prüfziffer/)

    # correct check digit
    invoice_config.update(account_number: '12-123-9')

    expect(invoice_config).to be_valid
  end

  it 'nullifies participant_number_internal unless payment_slip is ch_besr' do
    invoice_config.update(participant_number_internal: 1, payment_slip: 'ch_esr')
    expect(invoice_config.participant_number_internal).to be_nil

    invoice_config.update(participant_number_internal: 1, payment_slip: 'ch_besr')
    expect(invoice_config.participant_number_internal).to be_present
  end

  describe 'e-mail validation' do

    before { allow(Truemail).to receive(:valid?).and_call_original }

    it 'does not allow invalid e-mail address' do
      invoice_config.email = 'blabliblu-ke-email'

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:email].first).to eq('ist nicht gültig')
    end

    it 'allows blank e-mail address' do
      invoice_config.email = '   '

      expect(invoice_config).to be_valid
      expect(invoice_config.email).to be_nil
    end

    it 'does not allow e-mail address with non-existing domain' do
      invoice_config.email = 'invoices42@gitsäuäniä.it'

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:email].first).to eq('ist nicht gültig')
    end

    it 'does not allow e-mail address with domain without mx record' do
      invoice_config.email = 'invoices@bluewin.com'

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:email].first).to eq('ist nicht gültig')
    end

    it 'does allow valid e-mail address' do
      invoice_config.email = 'invoice42@puzzle.ch'

      expect(invoice_config).to be_valid
    end
  end
end
