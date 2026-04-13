# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplates::InvoiceRunsController, js: true do
  around do |example|
    original = Settings.groups.period_invoice_templates.enabled
    Settings.groups.period_invoice_templates.enabled = true
    Rails.application.reload_routes!
    example.run
    Settings.groups.period_invoice_templates.enabled = original
    Rails.application.reload_routes!
  end

  subject { page }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }

  before do
    sign_in(user)
    3.times do
      # 1 person with incomplete address
      Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_one))
      # 2 people with complete addresses in the same group
      p2 = Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two)).person
      p2.update!(street: "Greatstreet", zip_code: 8000, town: "Bern")
      p3 = Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two)).person
      p3.update!(street: "Greatstreet", zip_code: 8000, town: "Bern")
    end
    groups(:bottom_layer_two).update!(street: "Greatstreet", zip_code: 8000, town: "Bern")
    invoice_configs(:top_layer).update!(currency: "EUR")
  end

  context "with group recipients" do
    context "create and delete" do
      let(:index_path) { group_period_invoice_template_invoice_runs_path(group, period_invoice_template) }

      it "allows to create and delete an invoice run within a period invoice template" do
        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
        expect(page).to have_text "Mitgliedsbeitrag"
        expect(page).to have_text "45.00 EUR"

        fill_in "Titel", with: "Testlauf"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Testlauf wurde für 2 Empfänger erstellt."
        expect(page).to have_text "Bottom One"
        expect(page).to have_text "15.00 EUR"
        expect(page).to have_text "Bottom Two"
        expect(page).to have_text "30.00 EUR"

        expect(page).to have_text "2 Rechnungen angezeigt."
        within first("#main tbody tr") do
          click_link "Testlauf"
        end

        expect(page).not_to have_text "2 Rechnungen angezeigt."
        expect(page).to have_text "Mitgliedsbeitrag       3 0.00 % 5.00 EUR 15.00 EUR"
        page.go_back

        expect(page).to have_text "2 Rechnungen angezeigt."
        page.find("th input[type=checkbox]").check
        click_link "Stornieren"
        expect(page).to have_text "2 Rechnungen wurden storniert"

        page.find(".sheet ul.nav li.active", text: "Rechnungsläufe").click
        expect(page).to have_text period_invoice_template.name
        expect(page).to have_text "Weiteren Rechnungslauf fahren"

        page.find("[alt=\"Löschen\"]").click
        expect(page).to have_text "Willst du diesen Rechnungslauf wirklich löschen?"
        click_button "Löschen"

        expect(page).to have_text "Rechnungslauf wurde erfolgreich gelöscht."
        expect(page).to have_text "Keine Einträge gefunden"
        expect(page).to have_text "Rechnungslauf fahren"
        expect(page).not_to have_text "Weiteren Rechnungslauf fahren"
      end

      it "generates the invoices in the language of the receiver" do
        groups(:bottom_layer_two).update!(language: :fr)
        period_invoice_template.items.first.update!(name_fr: "cotisation des membres")

        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"

        fill_in "Titel", with: "Testlauf"
        first("button[data-bs-title*=\"weitere verfügbare Sprachen\"]").click
        first("input[name*=title_fr]").fill_in with: "Test FR"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Testlauf wurde für 2 Empfänger erstellt."
        expect(page).to have_text "2 Rechnungen angezeigt."
        expect(page).to have_text "Testlauf"
        expect(page).to have_text "Bottom One"
        expect(page).to have_text "Test FR"
        expect(page).to have_text "Bottom Two"

        click_link "Test FR"
        expect(page).to have_text "Rechnung stellen / mahnen"
        click_link "FR"
        expect(page).to have_text "Test FR"
        expect(page).to have_text "cotisation des membres"
        expect(page).not_to have_text "Mitgliedsbeitrag"
        expect(page).not_to have_text "Testlauf"
      end
    end

    context "multiple sequential invoice runs" do
      let(:index_path) { group_period_invoice_template_invoice_runs_path(group, period_invoice_template) }

      it "only considers new members added since the last invoice run" do
        # First invoice run
        # Should work normally
        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
        expect(page).to have_text "Mitgliedsbeitrag"
        expect(page).to have_text "45.00 EUR"

        fill_in "Titel", with: "Testlauf"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Testlauf wurde für 2 Empfänger erstellt."
        expect(page).to have_text "Bottom One"
        expect(page).to have_text "15.00 EUR"
        expect(page).to have_text "Bottom Two"
        expect(page).to have_text "30.00 EUR"

        # In the meantime, new people are added to hitobito
        2.times do
          Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two))
        end

        # Follow-up invoice run
        # Should only include the one new added role and ignore the previously invoiced ones.
        # Should not create any invoice for layers which contain no invoiceable roles at all.

        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
        expect(page).to have_text "Mitgliedsbeitrag"
        expect(page).to have_text "10.00 EUR"

        fill_in "Titel", with: "Zweiter Testlauf"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Zweiter Testlauf wurde für 2 Empfänger erstellt."
        expect(page).not_to have_text "Bottom One"
        expect(page).to have_text "Bottom Two"
        expect(page).to have_text "10.00 EUR"
      end
    end
  end

  context "with people recipients" do
    before do
      period_invoice_template.update(recipient_source:)
    end

    let(:recipient_source) {
      PeopleFilter.new(
        group: Group.root, filter_chain:, range: "deep", visible: false
      )
    }
    let(:filter_chain) {
      {
        role: {
          role_types: [],
          kind: "active",
          start_at: period_invoice_template.start_on.to_s,
          finish_at: period_invoice_template.end_on.to_s,
          include_archived: true
        }
      }
    }

    let(:index_path) { group_period_invoice_template_invoice_runs_path(group, period_invoice_template) }

    it "allows to create an invoice run within a period invoice template" do
      visit index_path
      click_link "Rechnungslauf fahren"

      expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
      expect(page).to have_text "Mitgliedsbeitrag"
      expect(page).to have_text "45.00 EUR"

      fill_in "Titel", with: "Testlauf"
      click_button "Speichern"

      expect(page).to have_text "Rechnung Testlauf wurde für 11 Empfänger erstellt."
      expect(page).to have_text "Für 3 Empfänger konnte keine gültige Rechnung erzeugt werden."
      expect(page).to have_text "5.00 EUR"

      expect(page).to have_text "6 Rechnungen angezeigt."
      within first("#main tbody tr") do
        click_link "Testlauf"
      end

      expect(page).not_to have_text "2 Rechnungen angezeigt."
      expect(page).to have_text "Mitgliedsbeitrag       1 0.00 % 5.00 EUR 5.00 EUR"
    end
  end
end
