# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe :invoices, js: true do
  subject { page }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }

  before { sign_in(user) }

  describe "multiselect" do
    let!(:invoices) do
      invoice_count.times.map do
        Fabricate(:invoice, creator: user, group: group, recipient: people(:bottom_member), state: :draft,
          invoice_items: [InvoiceItem.new(count: 1, unit_cost: 100, name: "Test")])
      end
    end

    context "with < 50 items" do
      let(:invoice_count) { 3 }

      it "selects all only visible invoices" do
        visit group_invoices_path(group)

        find("#all").click
        expect(page).to have_content("3 Ausgewählt")
        expect(page).not_to have_content("auswählen")

        find("#all").click
        expect(page).not_to have_content("Ausgewählt")

        find_all("input[name='ids[]']").sample.click

        expect(page).to have_content("1 Ausgewählt")
      end
    end

    context "with > 50 items" do
      let(:invoice_count) { 51 }

      it "selects all invoices and appends the ids to the action link" do
        visit group_invoices_path(group)

        find("#all").click
        expect(page).to have_content("50 Ausgewählt")
        expect(page).to have_content("Alle 51 auswählen")
        find("label.extended_all").click
        expect(page).to have_content("51 Ausgewählt")
        click_link("Rechnung stellen / mahnen")
        click_link("Status setzen (Gestellt/Gemahnt)")

        expect(group.invoices).to all(be_issued)
        expect(page).to have_content("51 Rechnungen wurden gestellt")
      end

      it "selects all invoices but regresses to visible invoices when deselected" do
        visit group_invoices_path(group)

        find("#all").click
        expect(page).to have_content("50 Ausgewählt")
        expect(page).to have_content("Alle 51 auswählen")
        find("label.extended_all").click
        expect(page).to have_content("51 Ausgewählt")

        find_all("input[name='ids[]']").sample.click

        expect(page).to have_content("49 Ausgewählt")
      end
    end
  end

  describe "invoice_runs" do
    let(:group) { groups(:bottom_layer_one) }
    let(:user) { people(:bottom_member) }

    let(:letter) { messages(:with_invoice) }
    let!(:sent) { invoices(:sent) }
    let!(:invoice_run) { letter.create_invoice_run(title: "test", group_id: group.id) }

    describe "GET #index" do
      before do
        update_issued_at_to_current_year
        sent.update(invoice_run: invoice_run)
      end

      it "shows separate export options when viewing invoice run invoices" do
        visit group_invoice_run_invoices_path(group_id: group.id, invoice_run_id: invoice_run.id)
        find("#all").click
        print = page.find_link("Drucken")
        print.click
        options = print.all(:xpath, "..//..//ul//li")
        expect(options.count).to eq 4
        expect(options[0].text).to eq "Rechnung inkl. Einzahlungsschein"
        expect(options[1].text).to eq "Rechnung separat"
        expect(options[2].text).to eq "Einzahlungsschein separat"
        expect(options[3].text).to eq "Originalrechnung inkl. Einzahlungsschein"
      end

      it "shows single letter_with_invoice export option when viewing invoices from letter with invoice" do
        invoice_run.update(message: letter)
        visit group_invoice_run_invoices_path(group_id: group.id, invoice_run_id: invoice_run.id)
        find("#all").click
        print = page.find_link("Drucken")
        print.click
        options = print.all(:xpath, "..//..//ul//li")
        expect(options.count).to eq 1
        expect(options.first.text).to eq "Rechnungsbriefe"
      end
    end

    def update_issued_at_to_current_year
      sent = invoices(:sent)
      if sent.issued_at.year != Time.zone.today.year
        sent.update(issued_at: Time.zone.today.beginning_of_year)
      end
    end
  end
end
