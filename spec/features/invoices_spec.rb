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
end
