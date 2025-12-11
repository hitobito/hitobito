require "spec_helper"

describe "invoice_runs/_form.html.haml" do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { group.issued_invoices.build }
  let(:invoice_run) { InvoiceRun.new(group: group, recipient_ids: "1,2", invoice: invoice) }
  let(:dom) { Capybara::Node::Simple.new(render) }

  before do
    allow(view).to receive_messages({
      current_user: person,
      parent: group,
      cancel_url: "",
      model_class: InvoiceRun,
      entry: invoice_run,
      path_args: [group, invoice_run]
    })

    allow(controller).to receive_messages(current_user: person)
  end

  describe "fixed fees" do
    before { allow(view).to receive(:fixed_fees?).and_return(true) }

    it "renders hidden fixed_fees param" do
      expect(dom).to have_css("input[name=fixed_fees]", visible: false)
    end

    it "renders invoice items table" do
      invoice.invoice_items.build(name: "pen", unit_cost: 10, count: 2)
      expect(dom).to have_css("tbody td", text: "pen")
    end
  end

  it "only renders invoice articles of group" do
    allow(view).to receive(:fixed_fees?).and_return(false)
    group.invoice_config.update(donation_calculation_year_amount: 1, donation_increase_percentage: 5)
    expect(group.invoice_articles).to have(3).items
    groups(:top_layer).invoice_articles.create!(number: 1, name: "test")

    expect(dom).to have_select("invoice_item_article", options: [
      "",
      "BEI-JU - Beitrag Kinder",
      "BEI-18 - Beitrag Erwachsene",
      "ABO-NEWS - Abonnement der Mitgliederzeitschrift"
    ])
  end
end
