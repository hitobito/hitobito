require "spec_helper"

describe "invoices/_table.html.haml" do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { Fabricate(:invoice, group: group, recipient: person) }
  let(:payed_invoice) { Fabricate(:invoice, group: group, recipient: person, state: :payed) }
  let(:invoices) { group.invoices }
  let(:paginated_invoices) { invoices.page(1).per(10) }
  let(:dom) { Capybara::Node::Simple.new(render) }

  before do
    assign(:invoices, paginated_invoices)
    allow(view).to receive(:entries).and_return(paginated_invoices)
    allow(view).to receive(:parent).and_return(group)
    allow(view).to receive(:url_for).and_return("/invoices?sort=title&sort_dir=asc")
    allow(view).to receive(:sortable?).and_return(true)
    allow(view).to receive(:invoice_list).and_return(nil)
    allow(view).to receive(:group).and_return(group)
    allow(view).to receive(:current_user).and_return(person)
  end

  it "shows current invoice count" do
    expect(dom).to have_text("2 Rechnungen angezeigt.")
  end
end
