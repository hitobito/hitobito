require 'spec_helper'

describe 'invoice_lists/_form.html.haml' do
  let(:group)   { groups(:bottom_layer_one) }
  let(:person)  { people(:bottom_member) }
  let(:invoice) { group.invoices.build }
  let(:dom)     { Capybara::Node::Simple.new(render) }

  before do
    allow(view).to receive_messages({
      current_user: person,
      parent: group,
      cancel_url: '',
      model_class: Invoice,
      entry: invoice,
      path_args: [group, invoice]
    })

    allow(controller).to receive_messages(current_user: person)
  end

  it 'only renders invoice articles of group' do
    expect(group.invoice_articles).to have(3).items
    groups(:top_layer).invoice_articles.create!(number: 1, name: 'test')

    expect(dom).to have_select('invoice_item_article', options: [
      "",
      "BEI-JU - Beitrag Kinder",
      "BEI-18 - Beitrag Erwachsene",
      "ABO-NEWS - Abonnement der Mitgliederzeitschrift"
    ])
  end

end
