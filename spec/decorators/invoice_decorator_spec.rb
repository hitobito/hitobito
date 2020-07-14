require 'spec_helper'

describe InvoiceDecorator do

  context :currency do
    it 'is read from invoice_config for new record' do
      group = groups(:top_layer)
      group.invoice_config.update(currency: 'EUR')
      expect(group.invoices.build.decorate.currency).to eq 'EUR'
    end

    it 'is read from invoice for persisted record' do
      invoice = invoices(:invoice)
      invoice.update(currency: 'EUR')
      expect(invoice.currency).to eq 'EUR'
    end
  end

end
