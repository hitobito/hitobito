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

  it 'includes payment reminder title and text' do
    reminder = Fabricate(:payment_reminder, invoice: sent, due_at: sent.due_at + 10.days)
    pdf = described_class.render(sent, articles: true)
    text = PDF::Inspector::Text.analyze(pdf).show_text
    expect(text).to include "#{reminder.title} - #{sent.title}"
    expect(text).to include reminder.text
  end

end
