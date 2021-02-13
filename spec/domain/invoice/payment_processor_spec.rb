require "spec_helper"

describe Invoice::PaymentProcessor do
  let(:invoice) { invoices(:sent) }
  let(:invoice_config) { invoice.invoice_config }

  it "parses 5 credit statements" do
    expect(parser.credit_statements).to have(5).items
  end

  it "builds payments for each credit statement" do
    expect(parser.payments).to have(5).items
    parser.payments.each do |payment|
      expect(payment).not_to be_valid
    end
  end

  it "first payment is marked as valid" do
    invoice.update_columns(reference: "000000000000100000000000905")
    payment = parser.payments.first
    expect(payment).to be_valid
  end

  it "creates payment and marks invoice as payed" do
    invoice.update_columns(reference: "000000000000100000000000905",
                           total: 710.82)
    expect do
      expect(parser.process).to eq 1
    end.to change { Payment.count }.by(1)
    expect(invoice.reload).to be_payed
  end

  it "creates payment and marks invoice as payed and updates invoice_list" do
    list = InvoiceList.create!(title: :title, group: invoice.group)
    invoice.update_columns(reference: "000000000000100000000000905",
                           invoice_list_id: list.id,
                           total: 710.82)
    expect do
      expect(parser.process).to eq 1
    end.to change { Payment.count }.by(1)
    expect(invoice.reload).to be_payed
    expect(list.reload.amount_paid.to_s).to eq "710.82"
    expect(list.reload.recipients_paid).to eq 1
  end

  it "invalid payments only produce set alert" do
    expect(parser.alert).to be_present
    expect(parser.notice).to be_blank
  end

  it "invalid and valid payments set alert and notice" do
    invoice.update_columns(reference: "000000000000100000000000905")
    expect(parser.alert).to be_present
    expect(parser.notice).to be_present
  end

  private

  def parser(file = "camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923")
    @parser ||= Invoice::PaymentProcessor.new(read(file))
  end

  def read(name)
    Rails.root.join("spec/fixtures/invoices/#{name}.xml").read
  end
end
