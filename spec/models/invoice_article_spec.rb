require "spec_helper"

RSpec.describe InvoiceArticle, type: :model do
  subject { invoice_articles(:beitrag) }

  it "has a nice string represenation" do
    expect(subject.to_s).to eq "BEI-18 - Beitrag Erwachsene"
  end
end
