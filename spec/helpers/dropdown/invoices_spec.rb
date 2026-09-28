#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Dropdown::Invoices" do
  include Rails.application.routes.url_helpers

  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:dropdown) do
    Dropdown::Invoices.new(
      self,
      :download
    )
  end

  before do
    params[:group_id] = group.id
    params[:controller] = "invoices"
    allow(self).to receive(:current_user).and_return(user)
  end

  describe "export" do
    let(:dom) { Capybara::Node::Simple.new(dropdown.export.to_s) }

    it "has csv and xslx export buttons" do
      expect(dom).to have_content "Export"
      expect(dom).to have_selector ".btn-group > ul.dropdown-menu"

      expect(dom).to have_selector ".btn-group > ul.dropdown-menu > li > a", text: "CSV"
      expect(dom).to have_selector ".btn-group > ul.dropdown-menu > li > a", text: "Excel"

      expect(dom).to have_link "Rechnungen", href: group_invoices_path(group, format: :csv)
      expect(dom).to have_link "Rechnungen", href: group_invoices_path(group, format: :xlsx)

      expect(dom).to have_link "Nicht zuordenbare Zahlungen",
        href: group_payments_path(group, format: :csv, status: :without_invoice)
      expect(dom).to have_link "Nicht zuordenbare Zahlungen",
        href: group_payments_path(group, format: :xlsx, status: :without_invoice)
    end

    it "export sub-items have data-checkable attribute needed for multiselect" do
      expect(dom).to have_selector("a[data-checkable='true']", text: "Rechnungen")
      expect(dom).to have_selector("a[data-checkable='true']", text: "Nicht zuordenbare Zahlungen")
    end
  end

  describe "print" do
    subject(:labels) { Dropdown::Invoices.new(self, :print, invoice: invoice).print.items.map(&:label) }

    context "without a specific invoice" do
      let(:invoice) { nil }

      it "offers the payment slip print variants, since it cannot know" do
        expect(labels).to include("Rechnung separat", "Einzahlungsschein separat")
      end
    end

    context "invoice has a payment slip" do
      let(:invoice) { invoices(:invoice) }

      it "offers the payment slip print variants" do
        expect(labels).to include("Rechnung separat", "Einzahlungsschein separat")
      end

      it "mentions the payment slip in the full and original invoice labels" do
        expect(labels).to include("Rechnung inkl. Einzahlungsschein", "Originalrechnung inkl. Einzahlungsschein")
      end
    end

    context "invoice has no payment slip" do
      let(:invoice) { Invoice.new(payment_slip: "no_ps") }

      it "does not offer the payment slip print variants" do
        expect(labels).not_to include("Rechnung separat", "Einzahlungsschein separat")
      end

      it "does not mention a payment slip in the full and original invoice labels" do
        expect(labels).to include("Rechnung", "Originalrechnung")
        expect(labels).not_to include("Rechnung inkl. Einzahlungsschein", "Originalrechnung inkl. Einzahlungsschein")
      end
    end
  end
end
