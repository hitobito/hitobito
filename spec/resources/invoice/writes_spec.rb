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

      describe "recipient detail attributes" do
        # the acting person is the recipient, so they may see their own details
        let(:invoice) { Fabricate(:invoice, group: groups(:bottom_layer_one), recipient: person) }

        let(:attrs) do
          payload.deep_merge(
            data: {
              relationships: {
                recipient: {
                  data: {
                    id: person.id.to_s,
                    type: "people",
                    method: "update"
                  }
                }
              }
            },
            included: [{
              id: person.id.to_s,
              type: "people",
              attributes: {
                additional_information: "Allergies"
              }
            }]
          )
        end

        it "can be updated with show_details permission" do
          instance = InvoiceResource.find(attrs)
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { person.reload.additional_information }.to("Allergies")
        end

        it "cannot be updated without show_details permission" do
          allow(ability).to receive(:can?).and_call_original
          allow(ability).to receive(:can?).with(:show_details, person).and_return(false)

          instance = InvoiceResource.find(attrs)
          expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
          expect(person.reload.additional_information).to be_blank
        end
      end
    end
  end
end
