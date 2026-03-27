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
        href: group_payments_path(group, format: :csv, state: :without_invoice)
      expect(dom).to have_link "Nicht zuordenbare Zahlungen",
        href: group_payments_path(group, format: :xlsx, state: :without_invoice)
    end
  end
end
