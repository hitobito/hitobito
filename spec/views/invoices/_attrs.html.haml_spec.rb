#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "invoices/_attrs.html.haml" do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { Fabricate(:invoice, group: group, recipient_email: "test@example.net") }
  let(:dom) { Capybara::Node::Simple.new(render) }

  before do
    allow(view).to receive_messages({
      current_user: person,
      parent: group,
      cancel_url: "",
      model_class: Invoice,
      entry: invoice.decorate,
      path_args: [group, invoice]
    })

    allow(controller).to receive_messages(current_user: person)
    allow(view).to receive(:parents).and_return([group])
    assign(:payment, Payment.build(invoice:))
  end

  describe "payment form" do
    subject(:payment_form) { dom.find("#new_payment") }

    it "renders correct path for invoice" do
      expect(payment_form["action"]).to eq group_invoice_payments_path(group, invoice)
      expect(payment_form.find("a.cancel")["href"]).to eq group_invoice_path(group, invoice)
    end

    it "renders correct path for invoice run invoice" do
      invoice_run = InvoiceRun.create!(title: "test", group:)
      invoice.update!(invoice_run:)
      expect(payment_form["action"]).to eq group_invoice_payments_path(group, invoice)
      expect(payment_form.find("a.cancel")["href"]).to eq group_invoice_run_invoice_path(group, invoice_run, invoice)
    end
  end
end
