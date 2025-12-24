# frozen_string_literal: true

# == Schema Information
#
# Table name: invoices
#
#  id                  :integer          not null, primary key
#  account_number      :string
#  address             :text
#  beneficiary         :text
#  currency            :string           default("CHF"), not null
#  description         :text
#  due_at              :date
#  esr_number          :string           not null
#  hide_total          :boolean          default(FALSE), not null
#  iban                :string
#  issued_at           :date
#  participant_number  :string
#  payee               :text
#  payment_information :text
#  payment_purpose     :text
#  payment_slip        :string           default("ch_es"), not null
#  recipient_address   :text
#  recipient_email     :string
#  reference           :string           not null
#  sent_at             :date
#  sequence_number     :string           not null
#  state               :string           default("draft"), not null
#  title               :string           not null
#  total               :decimal(12, 2)
#  vat_number          :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  creator_id          :integer
#  group_id            :integer          not null
#  invoice_run_id     :bigint
#  recipient_id        :integer
#
# Indexes
#
#  index_invoices_on_esr_number       (esr_number)
#  index_invoices_on_group_id         (group_id)
#  index_invoices_on_invoice_run_id  (invoice_run_id)
#  index_invoices_on_recipient_id     (recipient_id)
#  index_invoices_on_sequence_number  (sequence_number)
#

require "spec_helper"

describe Invoice do
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }
  let(:invoice_config) { invoice_configs(:top_layer) }

  it "sorts by sequence_number on list" do
    Invoice.destroy_all
    i1 = create_invoice(sequence_number: "1-10")
    i2 = create_invoice(sequence_number: "2-1")
    i3 = create_invoice(sequence_number: "1-2")

    expect(Invoice.list.map(&:to_s)).to eq [i3, i1, i2].map(&:to_s)
  end

  it "saving requires group, title and recipient" do
    invoice = create_invoice
    expect(invoice).to be_valid
  end

  it "saving increments number on invoice_config" do
    expect do
      2.times { create_invoice }
    end.to change { invoice_config.reload.sequence_number }.by(2)
  end

  it "validates that the structured address is specified if no recipient" do
    invoice = Invoice.create(title: "invoice", group: group)
    expect(invoice).not_to be_valid
    expect(invoice.errors.full_messages)
      .to include("Firmenname oder Name muss ausgefüllt werden")
    expect(invoice.errors.full_messages)
      .to include("Strasse muss ausgefüllt werden")
    expect(invoice.errors.full_messages)
      .to include("PLZ muss ausgefüllt werden")
    expect(invoice.errors.full_messages)
      .to include("Ort muss ausgefüllt werden")
    expect(invoice.errors.full_messages)
      .to include("Land muss ausgefüllt werden")
  end

  it "does not validate the structured address if issued_at in 2025 and no recipient, no structured address" do
    invoice = Invoice.create(title: "invoice", group: group, issued_at: Date.new(2025, 2, 12))
    expect(invoice).to be_valid
  end

  it "validates that on old invoices, at least one email or an address is specified if no recipient" do
    invoice = create_invoice
    invoice.update_columns(
      recipient_id: nil,
      recipient_email: nil,
      deprecated_recipient_address: nil,
      recipient_company_name: nil,
      recipient_name: nil,
      recipient_address_care_of: nil,
      recipient_street: nil,
      recipient_housenumber: nil,
      recipient_postbox: nil,
      recipient_zip_code: nil,
      recipient_town: nil
    )
    expect(invoice).not_to be_valid
    expect(invoice.errors.full_messages)
      .to include("Empfänger Adresse oder E-Mail muss ausgefüllt werden")
  end

  it "validates that an invoice in state issued or sent has at least has one invoice_item" do
    invoice = create_invoice
    invoice.update(state: :issued)
    expect(invoice).not_to be_valid
    expect(invoice.errors.full_messages).to include(/Rechnungsposten muss ausgefüllt werden/)
    invoice.reload.update(state: :sent)
    expect(invoice).not_to be_valid
    expect(invoice.errors.full_messages).to include(/Rechnungsposten muss ausgefüllt werden/)
  end

  describe "normalization" do
    it "downcases recipient_email" do
      invoice = create_invoice
      invoice.recipient_email = "TesTer@gMaiL.com"
      expect(invoice.recipient_email).to eq "tester@gmail.com"
    end
  end

  it "accepts that an invoice in state issued or sent has no items if  part of an invoice_run" do
    invoice = create_invoice
    invoice.update(invoice_run: InvoiceRun.create!(group: group, title: "list"))
    invoice.update(state: :issued)
    expect(invoice).to be_valid
    invoice.reload.update(state: :sent)
    expect(invoice).to be_valid
  end

  it "computes sequence_number based of group_id and invoice_config.sequence_number" do
    expect(create_invoice.sequence_number).to eq "#{group.id}-1"
  end

  it "#save sets recipient and related fields, keeps empty fields" do
    person.update!(zip_code: 3003, country: "CH", company: true, company_name: "Top ITC", address_care_of: "Office",
      postbox: "Postfach")

    invoice = create_invoice
    expect(invoice.recipient).to eq person
    expect(invoice.recipient_email).to eq person.email

    expect(invoice.recipient_company_name).to eq "Top ITC"
    expect(invoice.recipient_name).to eq "Top Leader"
    expect(invoice.recipient_address_care_of).to eq "Office"
    expect(invoice.recipient_street).to eq "Greatstreet"
    expect(invoice.recipient_housenumber).to eq "345"
    expect(invoice.recipient_postbox).to eq "Postfach"
    expect(invoice.recipient_zip_code).to eq "3003"
    expect(invoice.recipient_town).to eq "Greattown"
    expect(invoice.recipient_country).to eq "CH"
  end

  it "#save prefers additional email with invoice flag over recipient email" do
    person.additional_emails.create!(email: "invoices@example.com", label: "Privat", invoices: true)
    invoice = create_invoice
    expect(invoice.recipient_email).to eq "invoices@example.com"
  end

  it "#save sets esr_number but not participant_number for non esr invoice_config" do
    invoice = create_invoice(group: groups(:bottom_layer_one))
    expect(invoice.participant_number).to be_nil
    expect(invoice.esr_number).to be_present
    expect(invoice).not_to be_with_reference
  end

  it "#save calculates total for invoices at once" do
    invoice = Invoice.new(title: "invoice", group: group, recipient: person)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    expect { invoice.save! }.to change { InvoiceItem.count }.by(2)
    expect(invoice.total).to eq 2.5
  end

  it "#recalculate must be called when invoice item is added" do
    invoice = Invoice.create!(group: group, title: :title, recipient: person)
    expect(invoice.total).to eq(0)
    invoice.invoice_items.create!(name: "pens", unit_cost: 1.5)
    invoice.recalculate
    expect(invoice.total).to eq(1.5)
  end

  it "#to_s returns total amount" do
    invoice = invoices(:invoice)
    expect(invoice.to_s).to eq "Person Invoice(#{invoice.sequence_number}): 5.35"
  end

  it "#calculated returns summed fields of invoice_items, rounds to 0.05" do
    calculated = invoices(:invoice).calculated
    expect(calculated[:total]).to eq 5.35
    expect(calculated[:cost]).to eq 5.0
    expect(calculated[:vat]).to eq 0.35
  end

  it "#create sets payment attributes from invoice_config" do
    invoice = Invoice.create(title: "test_invoice", group: group)

    expect(invoice.address).to eq invoice_config.address
    expect(invoice.account_number).to eq invoice_config.account_number
    expect(invoice.iban).to eq invoice_config.iban
    expect(invoice.payment_slip).to eq invoice_config.payment_slip
    expect(invoice.beneficiary).to eq invoice_config.beneficiary
    expect(invoice.participant_number).to eq invoice_config.participant_number
    expect(invoice.vat_number).to eq invoice_config.vat_number
    expect(invoice.payee_name).to eq invoice_config.payee_name
    expect(invoice.payee_street).to eq invoice_config.payee_street
    expect(invoice.payee_housenumber).to eq invoice_config.payee_housenumber
    expect(invoice.payee_zip_code).to eq invoice_config.payee_zip_code
    expect(invoice.payee_town).to eq invoice_config.payee_town
    expect(invoice.payee_country).to eq invoice_config.payee_country
  end

  context "reference" do
    let(:iban) { "CH12 2134 1234 1234 1234" }
    let(:qr_iban) { "CH053 0000 0013 0003 6664" }
    let(:esr_without_blanks) { "000083496356700000000000019" }

    it "sets esr without blanks for qr invoice with qr iban" do
      group.invoice_config.update(payment_slip: :qr, iban: qr_iban)
      expect(create_invoice.reference).to eq esr_without_blanks
    end

    it "sets cors for qr invoice without qr iban" do
      group.invoice_config.update(payment_slip: :qr, iban: iban)
      expect(create_invoice.reference).to eq "RF29834963567Z1"
    end
  end

  context "state changes" do
    let(:now) { Time.zone.parse("2017-09-18 14:00:00") }
    let(:invoice) { invoices(:invoice) }

    before { travel_to(now) }

    it "creating sets state to draft" do
      expect(create_invoice.state).to eq "draft"
    end

    it "changing state to issued sets issued_at and due_at dates" do
      expect do
        invoice.update(state: :issued)
      end.to(change { [invoice.issued_at, invoice.due_at] })

      expect(invoice.due_at).to eq(now.to_date + 30.days)
      expect(invoice.issued_at).to eq(now.to_date)
      expect(invoice.sent_at).to be_nil
    end

    it "changing state to sent sets sent_at and due_at dates" do
      expect do
        invoice.update(state: :sent)
      end.to(change { [invoice.issued_at, invoice.sent_at, invoice.due_at] })

      expect(invoice.due_at).to eq(now.to_date + 30.days)
      expect(invoice.issued_at).to eq(now.to_date)
      expect(invoice.sent_at).to eq(now.to_date)
    end
  end

  context "#remindable?" do
    %w[issued sent partial reminded].each do |state|
      it "#{state} invoice is remindable" do
        expect(Invoice.new(state: state)).to be_remindable
      end
    end
    %w[draft payed excess cancelled].each do |state|
      it "#{state} invoice is not remindable" do
        expect(Invoice.new(state: state)).not_to be_remindable
      end
    end
  end

  it "knows a filename for the invoice-pdf" do
    invoice = create_invoice
    expect(invoice.sequence_number).to eq "834963567-1"
    expect(invoice.filename(:pdf)).to eq "Rechnung-834963567-1.pdf"
  end

  it "amount_open returns total amount minus payments" do
    invoice = invoices(:invoice)
    expect(invoice.amount_open).to eq 5.35

    invoice.payments.create!(amount: 4)
    expect(invoice.amount_open).to eq 1.35

    invoice.payments.create!(amount: 1.5)
    expect(invoice.amount_open).to eq(-0.15)
  end

  it "soft deleting group does not delete invoices" do
    other = Group::BottomLayer.create!(name: "x", parent: group)
    other.invoice_config.update(iban: "CH12 2134 1234 1234 1234",
      payee: "fuu",
      address: "fuu",
      account_number: "01-162-5")

    Fabricate(:invoice, group: other, recipient: person)
    expect { other.destroy }.not_to(change { other.issued_invoices.count })
  end

  it "hard deleting group does delete invoices" do
    other = Group::BottomLayer.create!(name: "x", parent: group)
    other.invoice_config.update(iban: "CH12 2134 1234 1234 1234",
      payee: "fuu",
      address: "fuu",
      account_number: "01-162-5")

    Fabricate(:invoice, group: other, recipient: person)
    expect { other.really_destroy! }.to(change { other.issued_invoices.count })
  end

  it "#order_by_sequence_number orders invoices correctly by sequence number" do
    Invoice.destroy_all
    i1 = create_invoice(sequence_number: "20-1")
    i2 = create_invoice(sequence_number: "1-3")
    i3 = create_invoice(sequence_number: "3-4")
    i4 = create_invoice(sequence_number: "1-1")
    i5 = create_invoice(sequence_number: "1-2")
    i6 = create_invoice(sequence_number: "19-20")

    expect(Invoice.order_by_sequence_number).to eq [i4, i5, i2, i3, i6, i1]
  end

  context ".with_aggregated_payments" do
    let(:invoice) { invoices(:invoice) }

    subject(:invoice_with_aggregated_payments) { Invoice.with_aggregated_payments.find_by(id: invoice.id) }

    it "amount_paid is 0 when no payments exists" do
      expect(invoice_with_aggregated_payments.amount_paid).to eq 0
    end

    it "amount_paid contains summed payments" do
      invoice.payments.create!(amount: 10)
      invoice.payments.create!(amount: 3)
      expect(invoice_with_aggregated_payments.amount_paid).to eq 13
    end

    it "last_payment_at is nil when no payments exists" do
      expect(invoice_with_aggregated_payments.last_payment_at).to be_nil
    end

    it "last_payment_at returns received at of latest payment" do
      invoice.payments.create!(amount: 10, received_at: 1.week.ago)
      invoice.payments.create!(amount: 3, received_at: Time.zone.today)
      expect(invoice_with_aggregated_payments.last_payment_at).to eq Time.zone.today
    end
  end

  context ".draft_or_issued_in" do
    let(:today) { Time.zone.parse("2019-12-16 10:00:00") }
    let(:invoice) { invoices(:invoice) }
    let(:issued) { invoices(:sent) }

    around do |example|
      travel_to(today) do
        Invoice.update_all(created_at: 2.months.ago)
        issued.update(
          issued_at: 1.month.ago,
          sent_at: 1.week.ago
        )
        example.call
      end
    end

    it "lists invoices sent or drafted in 2019" do
      expect(Invoice.draft_or_issued_in(2019)).to have(3).items
    end

    it "lists no invoices sent or drafted in other years" do
      expect(Invoice.draft_or_issued_in(2018)).to be_empty
      expect(Invoice.draft_or_issued_in(2020)).to be_empty
    end

    it "excludes invoice if issued in previous year" do
      issued.update(issued_at: 1.year.ago)
      expect(Invoice.draft_or_issued_in(2019)).not_to include issued
    end

    it "excludes invoice if created in previous year" do
      invoice.update(created_at: 1.year.ago)
      expect(Invoice.draft_or_issued_in(2019)).not_to include invoice
    end

    it "keeps scoping for invalid year" do
      expect(Invoice.draft_or_issued_in("invalid")).to have(3).items
    end
  end

  context ".draft_or_issued" do
    let(:today) { Time.zone.parse("2019-12-16 10:00:00") }
    let(:invoice) { invoices(:invoice) }
    let(:issued) { invoices(:sent) }

    around do |example|
      travel_to(today) do
        Invoice.update_all(created_at: 2.months.ago)
        issued.update(
          issued_at: 1.month.ago,
          sent_at: 1.week.ago
        )
        example.call
      end
    end

    it "lists invoices sent or drafted in 2019" do
      filter = Invoice.draft_or_issued(from: today.beginning_of_year, to: today.end_of_year)
      expect(filter).to have(3).items
    end

    it "lists no invoices sent or drafted in earlier years" do
      filter = Invoice.draft_or_issued(
        from: today.advance(years: -1).beginning_of_year,
        to: today.advance(years: -1).end_of_year
      )
      expect(filter).to be_empty
    end

    it "lists no invoices sent or drafted in later years" do
      filter = Invoice.draft_or_issued(
        from: today.advance(years: 1).beginning_of_year,
        to: today.advance(years: 1).end_of_year
      )
      expect(filter).to be_empty
    end

    it "excludes invoice if issued in previous year" do
      issued.update(issued_at: 1.year.ago)
      filter = Invoice.draft_or_issued(from: today.beginning_of_year, to: today.end_of_year)
      expect(filter).not_to include issued
    end

    it "excludes invoice if created in previous year" do
      invoice.update(created_at: 1.year.ago)
      filter = Invoice.draft_or_issued(from: today.beginning_of_year, to: today.end_of_year)
      expect(filter).not_to include invoice
    end

    it "does not crash with invalid dates" do
      expect(Invoice.draft_or_issued(from: "0", to: Date.new(2019, 12, 31))).to have(3).items
      expect(Invoice.draft_or_issued(from: Date.new(2019, 1, 1), to: nil)).to have(3).items
      expect(Invoice.draft_or_issued(from: "blørbaël", to: "Zórgðœ")).to have(3).items
    end
  end

  context "sorting" do
    it "needs to know about last payments" do
      expect(described_class.last_payments_information).to match(
        /LEFT OUTER JOIN \(.*\) AS last_payments ON invoices.id = last_payments.invoice_id/
      )

      expect(described_class.last_payments_information)
        .to match(/\( SELECT .* FROM payments GROUP BY invoice_id \)/)

      expect(described_class.last_payments_information)
        .to match(/invoice_id, MAX\(received_at\) AS last_payment_at, SUM\(amount\) AS amount_paid/)
    end

    it "supports sorting by last payment-date" do
      expect(described_class.order_by_payment_statement)
        .to eql "last_payments.last_payment_at"
    end

    it "supports sorting by totally paid amount" do
      expect(described_class.order_by_amount_paid_statement)
        .to eql "last_payments.amount_paid"
    end
  end

  describe "latest_reminder" do
    let(:invoice) { create_invoice }

    before do
      invoice.update!(due_at: 10.days.ago, state: "reminded")
    end

    it "returns latest reminder" do
      first_reminder = Fabricate(:payment_reminder, invoice: invoice, due_at: 3.days.ago, created_at: 5.days.ago)
      expect(invoice.latest_reminder).to eq first_reminder

      second_reminder = Fabricate(:payment_reminder, invoice: invoice, due_at: 1.day.ago, created_at: 2.days.ago)
      expect(invoice.reload.latest_reminder).to eq second_reminder
    end

    it "returns nil when no reminder is present" do
      expect(invoice.latest_reminder).to be_nil
    end
  end

  private

  def create_invoice(attrs = {})
    invoice = Invoice.create!(
      attrs.reverse_merge(title: "invoice", group: group, recipient: person)
    )
    invoice.update_attribute(:sequence_number, attrs[:sequence_number]) if attrs[:sequence_number]
    invoice
  end
end
