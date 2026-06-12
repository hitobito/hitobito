#  frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require "spec_helper"

describe InvoiceResource, type: :resource do
  let(:invoice) { invoices(:invoice) }
  let(:person) { people(:bottom_member) }
  let(:pens) { invoice_items(:pens) }

  describe "creating" do
    let(:group) { groups(:bottom_layer_one) }
    let(:recipient) { people(:top_leader) }

    let(:payload) do
      {
        data: {
          type: "invoices",
          attributes: {
            group_id: group.id,
            title: "Membership 2026",
            recipient_type: "Person",
            recipient_id: recipient.id
          }
        }
      }
    end

    let(:instance) { InvoiceResource.build(payload) }

    it "works" do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Invoice.count }.by(1)

      new_invoice = Invoice.order(:created_at).last
      expect(new_invoice.title).to eq("Membership 2026")
      expect(new_invoice.group).to eq(group)
      expect(new_invoice.recipient).to eq(recipient)
      # before_validation :set_recipient_fields populates address from the
      # polymorphic recipient association.
      expect(new_invoice.recipient_first_name).to be_present
      expect(new_invoice.recipient_last_name).to be_present
      expect(new_invoice.state).to eq("draft")
    end

    context "without group_id" do
      before { payload[:data][:attributes].delete(:group_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    describe "sideposting invoice_items" do
      it "creates invoice with line items in one request" do
        attrs = payload.deep_merge(
          data: {
            relationships: {
              invoice_items: {
                data: [
                  {"temp-id": "item-1", type: "invoice_items", method: "create"},
                  {"temp-id": "item-2", type: "invoice_items", method: "create"}
                ]
              }
            }
          },
          included: [
            {
              "temp-id": "item-1",
              type: "invoice_items",
              attributes: {name: "Member fee", unit_cost: 65.0, count: 1}
            },
            {
              "temp-id": "item-2",
              type: "invoice_items",
              attributes: {name: "Camp surcharge", unit_cost: 10.0, count: 1}
            }
          ]
        )
        instance = InvoiceResource.build(attrs)
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { Invoice.count }.by(1)
          .and change { InvoiceItem.count }.by(2)

        new_invoice = Invoice.order(:created_at).last
        expect(new_invoice.invoice_items.pluck(:name))
          .to contain_exactly("Member fee", "Camp surcharge")
      end

      it "fails when a sideposted invoice_item is invalid" do
        # InvoiceItem.validates :name, presence: true — an empty name aborts
        # the sideposted save and no Invoice row is created.
        attrs = payload.deep_merge(
          data: {
            relationships: {
              invoice_items: {
                data: [
                  {"temp-id": "item-1", type: "invoice_items", method: "create"}
                ]
              }
            }
          },
          included: [
            {
              "temp-id": "item-1",
              type: "invoice_items",
              attributes: {name: "", unit_cost: 65.0, count: 1}
            }
          ]
        )
        instance = InvoiceResource.build(attrs)
        expect {
          expect(instance.save).to eq(false)
        }.not_to change { Invoice.count }
      end
    end

    context "service token" do
      let(:token) { service_tokens(:permitted_top_layer_token) }
      let(:current_ability) { TokenAbility.new(token) }

      it "can create with finance permission" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { Invoice.count }.by(1)
      end

      it "cannot create when token has layer_read only" do
        token.update!(permission: :layer_read)
        allow(Graphiti.context[:object]).to receive(:current_ability)
          .and_return(TokenAbility.new(token))
        expect {
          expect(instance.save).to eq(true)
        }.to raise_error(CanCan::AccessDenied)
      end

      it "cannot create when token lacks invoices scope" do
        token.update!(invoices: false)
        allow(Graphiti.context[:object]).to receive(:current_ability)
          .and_return(TokenAbility.new(token))
        expect {
          expect(instance.save).to eq(true)
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "updating" do
    def payload(**attrs)
      {
        data: {
          id: invoice.id.to_s,
          type: "invoices",
          attributes: attrs.to_h
        }
      }
    end

    it "can update any attribute" do
      instance = InvoiceResource.find(payload(title: "new title"))
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { invoice.reload.title }.to("new title")
    end

    describe "sideposting" do
      it "can update existing invoice item" do
        attrs = payload.deep_merge(
          data: {
            relationships: {
              invoice_items: {
                data: [
                  {
                    id: pens.id,
                    type: "invoice_items",
                    method: "update"
                  }
                ]
              }
            }
          },
          included: [{
            id: pens.id,
            type: "invoice_items",
            attributes: {
              name: "pens - updated"
            }
          }]
        )
        instance = InvoiceResource.find(attrs)
        expect {
          expect(instance.update_attributes).to eq(true)
        }.to change { pens.reload.name }.from("pens").to("pens - updated")
      end

      it "can create new invoice item" do
        attrs = payload.deep_merge(
          data: {
            relationships: {
              invoice_items: {
                data: [
                  {
                    "temp-id": -1,
                    type: "invoice_items",
                    method: "create"
                  }
                ]
              }
            }
          },
          included: [{
            "temp-id": -1,
            type: "invoice_items",
            attributes: {
              name: "pens - new",
              unit_cost: 0.5
            }
          }]
        )
        instance = InvoiceResource.find(attrs)
        expect {
          expect(instance.update_attributes).to eq(true)
        }.to change { invoice.invoice_items.count }.by(1)
      end
    end
  end
end
