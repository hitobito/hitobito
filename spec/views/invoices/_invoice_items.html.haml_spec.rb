#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "invoices/_invoice_items.html.haml" do
  let(:group) { groups(:bottom_layer_one) }
  let(:recipient) { people(:bottom_member) }
  let(:invoice) { Fabricate(:invoice, group: group, recipient: recipient) }
  let(:dom) { Capybara::Node::Simple.new(render) }

  before do
    invoice.invoice_items.create!(name: "Stift", name_fr: "Crayon",
      description: "Blau", description_fr: "Bleu", unit_cost: 1, count: 1)
    allow(view).to receive(:entry).and_return(invoice.reload.decorate)
  end

  it "renders item texts in the language of the recipient" do
    recipient.update!(language: :fr)

    expect(dom).to have_css("td", text: "Crayon")
    expect(dom).to have_css("td", text: "Bleu")
  end

  it "renders column headers in the language of the user" do
    recipient.update!(language: :fr)

    expect(dom).to have_css("th", text: "Beschreibung")
  end

  it "falls back to another language without translation for the recipient" do
    recipient.update!(language: :it)

    expect(dom).to have_css("td", text: "Crayon")
  end

  it "renders item texts in the language of the user without recipient" do
    invoice.update_columns(recipient_id: nil, recipient_type: nil)

    expect(dom).to have_css("td", text: "Stift")
    expect(dom).to have_css("td", text: "Blau")
  end
end
