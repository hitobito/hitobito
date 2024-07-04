#  frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require "spec_helper"

describe InvoiceResource, type: :resource do
  let(:invoice) { invoices(:invoice) }
  let(:person) { people(:bottom_member) }

  describe "serialization" do
    def serialized_attrs
      [
        :title,
        :description,
        :state,
        :due_at,
        :issued_at,
        :recipient_email,
        :payment_information,
        :payment_purpose,
        :hide_total,
        :group_id,
        :recipient_id
      ]
    end

    it "works" do
      params[:filter] = {id: {eq: invoice.id}}
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id,
        :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(invoice.id)
      expect(data.jsonapi_type).to eq("invoices")
      expect(data.attributes["type"]).to be_blank
    end
  end

  describe "including" do
    it "may include items" do
      params[:include] = "invoice_items"
      render
      item = d[0].sideload(:invoice_items)[0]
      expect(item.name).to eq "pins"
      expect(item.description).to be_blank
      expect(item.unit_cost).to eq 0.5
      expect(item.vat_rate).to be_nil
      expect(item.cost).to be_nil
      expect(item.count).to eq 1
      expect(item.account).to be_nil
      expect(item.cost_center).to be_nil
    end

    it "may include group" do
      params[:include] = "group"
      render
      recipient = d[0].sideload(:group)
      expect(recipient).to be_present
    end

    it "may include recipient" do
      params[:filter] = {id: invoice.id}
      params[:include] = "recipient"
      invoice.update!(recipient: person)
      render
      recipient = d[0].sideload(:recipient)
      expect(recipient).to be_present
    end
  end

  describe "filtering" do
    let(:sent) { invoices(:sent) }
    let(:top_leader) { people(:top_leader) }
    let(:top_layer) { groups(:top_layer) }
    let(:bottom_layer_one) { groups(:bottom_layer_one) }
    let(:bottom_member) { people(:bottom_member) }
    let(:bottom_group_one_one) { groups(:bottom_group_one_one) }

    before do
      sent.update!(recipient: top_leader)
      invoice.update(recipient: bottom_member, group: bottom_group_one_one)
    end

    describe "by group_id" do
      it "returns only invoices matching group id" do
        params[:filter] = {group_id: bottom_group_one_one.id}
        render
        expect(jsonapi_data).to have(1).items
        expect(jsonapi_data[0].id).to eq invoice.id
      end
    end

    describe "by recipient_id" do
      it "returns only invoices matching recipient_id" do
        params[:filter] = {recipient_id: top_leader.id}
        render
        expect(jsonapi_data).to have(1).items
        expect(jsonapi_data[0].id).to eq sent.id
      end
    end
  end
end
