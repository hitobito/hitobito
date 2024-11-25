# == Schema Information
#
# Table name: invoice_articles
#
#  id          :integer          not null, primary key
#  account     :string
#  category    :string
#  cost_center :string
#  description :text
#  name        :string           not null
#  number      :string
#  unit_cost   :decimal(12, 2)
#  vat_rate    :decimal(5, 2)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  group_id    :integer          not null
#
# Indexes
#
#  index_invoice_articles_on_number_and_group_id  (number,group_id) UNIQUE
#

require "spec_helper"

RSpec.describe InvoiceArticle, type: :model do
  subject { invoice_articles(:beitrag) }

  it "has a nice string represenation" do
    expect(subject.to_s).to eq "BEI-18 - Beitrag Erwachsene"
  end
end
