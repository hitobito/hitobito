# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe Export::Pdf::Invoice do
  let(:invoice) { invoices(:invoice) }
  let(:sent)    { invoices(:sent) }

  it 'renders invoice with articles and payment_slip' do
    described_class.render(invoice, articles: true, payment_slip: true)
  end

  it 'renders empty invoice articles' do
    described_class.render(invoice, articles: true)
  end

  it 'renders empty invoice articles' do
    described_class.render(invoice, articles: true)
  end

  it 'renders empty invoice payment slip if without codeline' do
    expect_any_instance_of(Invoice::PaymentSlip).not_to receive(:code_line)
    described_class.render(Invoice.new(esr_number: 1, participant_number: 1),  payment_slip: true )
  end

  context 'currency' do
    subject do
      pdf = described_class.render(invoice, articles: true)
      PDF::Inspector::Text.analyze(pdf).show_text.compact.join(' ')
    end

    it 'defaults to CHF' do
      expect(subject).to match 'Gesamtbetrag 5.35 CHF'
    end

    it 'is read from settings' do
      allow(Settings.currency).to receive(:unit).and_return('EUR')
      expect(subject).to match 'Gesamtbetrag 5.35 EUR'
      expect(subject).not_to match 'CHF'
    end
  end

  it 'includes payment reminder title and text' do
    reminder = Fabricate(:payment_reminder, invoice: sent, due_at: sent.due_at + 10.days)
    pdf = described_class.render(sent, articles: true)
    text = PDF::Inspector::Text.analyze(pdf).show_text
    expect(text).to include "#{reminder.title} - #{sent.title}"
    expect(text).to include reminder.text
  end

  context 'address' do
    it 'address with 8 lines does not cause page break' do
      invoice.update(address: 1.upto(8).to_a.join("\n"))
      pdf = described_class.render(invoice, articles: true)
      expect(PDF::Inspector::Page.analyze(pdf).pages.size).to eq 1
    end

    it 'address with 9 lines causes page break' do
      invoice.update(address: 1.upto(9).to_a.join("\n"))
      pdf = described_class.render(invoice, articles: true)
      expect(PDF::Inspector::Page.analyze(pdf).pages.size).to eq 2
    end
  end

  context 'codeline' do
    let(:invoice) { Invoice.new(sequence_number: '1-2', participant_number: 1) }

    subject do
      pdf = described_class.render(invoice, payment_slip: true)
      PDF::Inspector::Text.analyze(pdf)
    end

    before do
      ['invoice_address',
       'account_number',
       'amount',
       'esr_number',
       'payment_purpose',
       'left_receiver_address',
       'right_receiver_address',
      ].each do  |method|
        allow_any_instance_of(Export::Pdf::Invoice::PaymentSlip).to receive(method.to_sym)
      end
    end

    it 'with ch_esr' do
      invoice.payment_slip = 'ch_esr'
      expect(subject.positions).to eq [[323.5819133858268, 44.532913385826845]]
      expect(subject.show_text.first).to eq '042>000000000000100000000000023+ 1>'
    end

    it "with ch_besr" do
      invoice.payment_slip = 'ch_besr'
      expect(subject.positions).to eq [[323.5819133858268, 44.532913385826845]]
      expect(subject.show_text.first).to eq '042>000000000000100000000000023+ 1>'
    end

    it "with ch_besr" do
      invoice.payment_slip = 'ch_besr'
      expect(subject.positions).to eq [[323.5819133858268, 44.532913385826845]]
      expect(subject.show_text.first).to eq '042>000000000000100000000000023+ 1>'
    end


    context 'fixutre' do
      let(:invoice) { invoices(:invoice) }

      it 'has code_line' do
        expect(subject.positions).to eq [[271.95971338582683, 44.532913385826845],
                                         [463.69931338582677, 44.532913385826845]]

        expect(subject.show_text.compact).to eq ['0100000005353>000037680338900000000000021+',
                                                 '376803389000004>']
      end
    end
  end
end
