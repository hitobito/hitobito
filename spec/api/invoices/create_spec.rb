# frozen_string_literal: true

require "rails_helper"

describe "invoices#create", type: :request do
  let(:group) { groups(:top_layer) }
  let(:recipient) { people(:bottom_member) }

  it_behaves_like "jsonapi authorized requests", required_scopes: [:invoices, :people] do
    let(:payload) {
      {
        data: {
          type: "invoices",
          attributes: {
            group_id: group.id,
            title: "Membership 2026",
            recipient_id: recipient.id
          }
        }
      }
    }

    subject(:make_request) do
      jsonapi_post "/api/invoices", payload
    end

    describe "basic create" do
      it "creates the resource" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { group.issued_invoices.count }.by(1)
      end
    end

    describe "invalid invoice with items" do
      before do
        payload[:data][:attributes][:title] = ""
        payload[:data][:relationships] = {
          invoice_items: {data: [{"temp-id": "item-1", type: "invoice_items", method: "create"}]}
        }
        payload[:included] = [
          {"temp-id": "item-1", type: "invoice_items", attributes: {name: "Fee", unit_cost: 10, count: 1}}
        ]
      end

      it "responds with the validation errors" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
        }.not_to change { Invoice.count }
      end
    end
  end
end
