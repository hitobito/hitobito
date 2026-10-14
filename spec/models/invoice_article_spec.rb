require "spec_helper"

RSpec.describe InvoiceArticle, type: :model do
  subject { invoice_articles(:beitrag) }

  it "has a nice string represenation" do
    expect(subject.to_s).to eq "BEI-18 - Beitrag Erwachsene"
  end

  it "has translated name and description" do
    subject.update!(name_fr: "Cotisation adultes", description_fr: "Cotisation normale")

    I18n.with_locale(:fr) do
      expect(subject.reload.name).to eq "Cotisation adultes"
      expect(subject.description).to eq "Cotisation normale"
    end
  end

  describe "name uniqueness" do
    let(:article) { InvoiceArticle.new(group: subject.group, number: "NEW") }

    it "is invalid with the name of another article of the group in any case" do
      article.name = "beitrag erwachsene"

      expect(article).not_to be_valid
      expect(article.errors[:name]).to be_present
    end

    it "is invalid with the translated name of another article of the group in that language" do
      subject.update!(name_fr: "Cotisation adultes")

      I18n.with_locale(:fr) do
        article.name = "Cotisation adultes"

        expect(article).not_to be_valid
      end
    end

    it "is valid with the name another article of the group has in another language" do
      subject.update!(name_fr: "Cotisation adultes")
      article.name = "Cotisation adultes"

      expect(article).to be_valid
    end

    it "is valid with the name of an article of another group" do
      article.group = groups(:bottom_layer_two)
      article.name = "Beitrag Erwachsene"

      expect(article).to be_valid
    end

    it "keeps an existing article valid" do
      expect(subject).to be_valid
    end
  end
end
