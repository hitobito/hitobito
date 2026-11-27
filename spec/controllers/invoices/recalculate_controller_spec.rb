#  Copyright (c) 2017-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoices::RecalculateController do
  let(:group) { groups(:bottom_layer_one) }

  before { sign_in(user) }

  describe "authorization" do
    context "as person with finance role" do
      let(:user) { Fabricate(Group::BottomLayer::Member.sti_name.to_sym, group: group).person }

      it "may recalculate when person has finance permission on layer group" do
        get :new, xhr: true, params: {group_id: group.id}
        expect(response).to be_successful
      end

      it "may recalculate when position is an invoice item" do
        controller = described_class.new
        controller.params = {group_id: invoices(:invoice).group.id,
          _method: :patch,
          invoice: {
            invoice_items_attributes: {
              "0" => {
                name: "Mitgliederbeitrag",
                id: invoice_items(:pens).id
              }
            }
          }}

        expect { controller.send(:entry) }.not_to raise_error
      end
    end

    context "as person without finance role" do
      let(:user) { Fabricate(Group::BottomLayer::BasicPermissionsOnly.sti_name.to_sym, group: group).person }

      it "may not recalculate when person has no finance permission on layer group" do
        get :new, xhr: true, params: {group_id: group.id}
        expect(response).to have_http_status(403)
      end
    end
  end

  context "with prices including vat" do
    let(:user) { people(:bottom_member) }

    before { group.invoice_config.update_columns(prices_include_vat: true) }

    it "calculates totals from unit cost including vat" do
      get :new, xhr: true, params: {group_id: group.id, invoice: {invoice_items_attributes: {
        "0" => {name: "pen", unit_cost: "10.81", vat_rate: "8.1", count: "2"}
      }}}

      expect(controller.send(:entry).invoice_items.first.unit_cost).to eq 10.0
    end

    it "calculates totals of invoice run from unit cost including vat" do
      get :new, xhr: true, params: {group_id: group.id, invoice_run: {invoice: {invoice_items_attributes: {
        "0" => {name: "pen", unit_cost: "10.81", vat_rate: "8.1", count: "2"}
      }}}}

      expect(controller.send(:entry).invoice_items.first.unit_cost).to eq 10.0
    end
  end
end
