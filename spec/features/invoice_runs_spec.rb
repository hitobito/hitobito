# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRunsController, js: true do
  let(:group) { groups(:bottom_layer_one) }
  let(:user) { people(:bottom_member) }
  let(:list) { mailing_lists(:leaders) }

  before do
    sign_in(user)
    Subscription.create!(mailing_list: list, subscriber: people(:top_leader))
  end

  it "creates invoice run with all attributes and invoice items" do
    visit new_group_invoice_run_path(group, invoice_run: {
      recipient_source_id: list.id,
      recipient_source_type: "MailingList"
    })

    expect(page).to have_text "Rechnungslauf"

    # Fill in invoice run title
    fill_in "Titel", with: "Membership Fee 2026"

    # Fill in invoice attributes
    fill_in "Text", with: "Annual membership fee"
    fill_in "Zahlungsinformation", with: "Please pay within 30 days"
    fill_in "Zahlungszweck", with: "Membership 2026"

    # Fill in issued date
    fill_in "Gestellt am", with: "01.04.2026"

    # Add first invoice item
    click_link "Eintrag hinzufügen"
    within all("#invoice_items_fields .fields").first do
      fill_in "Name", with: "Basic Membership"
      fill_in "Beschreibung", with: "Annual basic membership"
      fill_in "Kostenstelle", with: "42"
      fill_in "Konto", with: "123-456-789"
      fill_in "MwSt.", with: "19.00"
      fill_in "Preis", with: "50.00"
      fill_in "Anzahl", with: "1"
    end

    # Add second invoice item
    click_link "Eintrag hinzufügen"
    within all("#invoice_items_fields .fields").last do
      fill_in "Name", with: "Newsletter Subscription"
      fill_in "Beschreibung", with: "Monthly newsletter"
      fill_in "Kostenstelle", with: "43"
      fill_in "Konto", with: "234-567-890"
      fill_in "MwSt.", with: "1.00"
      fill_in "Preis", with: "5.00"
      fill_in "Anzahl", with: "12"
    end

    first(:button, "Speichern").click

    # Should create the invoice run and redirect with success message
    expect(page).to have_text "Rechnung Membership Fee 2026 wurde"

    # Verify invoice run was created with correct attributes
    invoice_run = InvoiceRun.last
    expect(invoice_run.title).to eq "Membership Fee 2026"
    expect(invoice_run.recipient_source).to eq list

    # Verify invoice was created for the subscriber
    expect(invoice_run.invoices.count).to eq 1
    invoice = invoice_run.invoices.first

    expect(invoice.title).to eq "Membership Fee 2026"
    expect(invoice.description).to eq "Annual membership fee"
    expect(invoice.payment_information).to eq "Please pay within 30 days"
    expect(invoice.payment_purpose).to eq "Membership 2026"
    expect(invoice.recipient).to eq people(:top_leader)

    # Verify invoice items
    expect(invoice.invoice_items.count).to eq 2

    item1 = invoice.invoice_items.find_by(name: "Basic Membership")
    expect(item1.description).to eq "Annual basic membership"
    expect(item1.count).to eq 1
    expect(item1.unit_cost).to eq 50.00
    expect(item1.vat_rate).to eq 19.00

    item2 = invoice.invoice_items.find_by(name: "Newsletter Subscription")
    expect(item2.description).to eq "Monthly newsletter"
    expect(item2.count).to eq 12
    expect(item2.unit_cost).to eq 5.00
    expect(item2.vat_rate).to eq 1.00

    # Verify total (50.00 * 1 * 1.19 + 5.00 * 12 * 1.01 = 59.50 + 60.60 = 120.10)
    expect(invoice.total).to eq 120.10
  end

  it "creates invoice run using invoice articles from select" do
    # Create invoice articles for the group
    _article1 = InvoiceArticle.create!(
      group: group,
      number: "MEM-001",
      name: "Adult Membership",
      description: "Annual membership for adults",
      category: "Memberships",
      unit_cost: 75.00,
      vat_rate: 7.7,
      cost_center: "MEM",
      account: "3000"
    )

    _article2 = InvoiceArticle.create!(
      group: group,
      number: "MAG-001",
      name: "Magazine Subscription",
      description: "Monthly magazine",
      category: "Publications",
      unit_cost: 8.50,
      vat_rate: 2.5,
      cost_center: "PUB",
      account: "3100"
    )

    visit new_group_invoice_run_path(group, invoice_run: {
      recipient_source_id: list.id,
      recipient_source_type: "MailingList"
    })

    expect(page).to have_text "Rechnungslauf"

    # Fill in invoice run title
    fill_in "Titel", with: "Annual Fees 2026"

    # Fill in invoice attributes
    fill_in "Text", with: "Annual membership and magazine fees"
    fill_in "Zahlungsinformation", with: "Payment due within 30 days"
    fill_in "Gestellt am", with: "01.04.2026"

    # Select first invoice article from dropdown
    # This will trigger JS that adds a new invoice item and populates it with article data
    select "MEM-001 - Adult Membership", from: "invoice_item_article"

    # Wait for the item to be added and filled
    expect(page).to have_css("#invoice_items_fields .fields", count: 1)

    # Fill in count for the auto-populated item
    within all("#invoice_items_fields .fields").first do
      fill_in "Anzahl", with: "1"
    end

    # Select second invoice article from dropdown
    select "MAG-001 - Magazine Subscription", from: "invoice_item_article"

    # Wait for the second item to be added
    expect(page).to have_css("#invoice_items_fields .fields", count: 2)

    # Fill in count for the second auto-populated item
    within all("#invoice_items_fields .fields").last do
      fill_in "Anzahl", with: "12"
    end

    first(:button, "Speichern").click

    # Should create the invoice run and redirect with success message
    expect(page).to have_text "Rechnung Annual Fees 2026 wurde"

    # Verify invoice run was created
    invoice_run = InvoiceRun.last
    expect(invoice_run.title).to eq "Annual Fees 2026"

    # Verify invoice was created with items from articles
    expect(invoice_run.invoices.count).to eq 1
    invoice = invoice_run.invoices.first

    expect(invoice.title).to eq "Annual Fees 2026"
    expect(invoice.description).to eq "Annual membership and magazine fees"
    expect(invoice.invoice_items.count).to eq 2

    # Verify first item matches article1
    # Article fields map directly to invoice item fields
    item1 = invoice.invoice_items.first
    expect(item1.name).to eq "Adult Membership"
    expect(item1.description).to eq "Annual membership for adults"
    expect(item1.count).to eq 1
    expect(item1.unit_cost).to eq 75.00
    expect(item1.vat_rate).to eq 7.7
    expect(item1.cost_center).to eq "MEM"
    expect(item1.account).to eq "3000"

    # Verify second item matches article2
    item2 = invoice.invoice_items.last
    expect(item2.name).to eq "Magazine Subscription"
    expect(item2.description).to eq "Monthly magazine"
    expect(item2.count).to eq 12
    expect(item2.unit_cost).to eq 8.50
    expect(item2.vat_rate).to eq 2.5
    expect(item2.cost_center).to eq "PUB"
    expect(item2.account).to eq "3100"

    # Verify total (75.00 * 1 * 1.077 + 8.50 * 12 * 1.025 = 80.775 + 104.55 = 185.325, rounded to 185.35)
    expect(invoice.total).to eq 185.35
  end
end
