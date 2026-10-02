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
    let(:recipient) do
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: group,
        person: Fabricate(:person_with_address)).person
    end

    let(:payload) do
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
      expect(new_invoice.recipient_first_name).to eq(recipient.first_name)
      expect(new_invoice.recipient_last_name).to eq(recipient.last_name)
      expect(new_invoice.recipient_town).to eq(recipient.town)
      expect(new_invoice.state).to eq("draft")
      expect(new_invoice.creator).to eq(person)
    end

    it "keeps recipient attributes given in the payload" do
      payload[:data][:attributes][:recipient_town] = "Elsewhere"

      expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      expect(Invoice.order(:created_at).last.recipient_town).to eq("Elsewhere")
    end

    it "does not accept a state" do
      payload[:data][:attributes][:state] = "issued"

      expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
    end

    context "without group_id" do
      before { payload[:data][:attributes].delete(:group_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "without recipient_id" do
      before do
        payload[:data][:attributes].delete(:recipient_id)
        payload[:data][:attributes].merge!(
          recipient_company_name: "Acme AG",
          recipient_zip_code: "3000",
          recipient_town: "Bern",
          recipient_country: "CH"
        )
      end

      it "creates an invoice without recipient" do
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence

        new_invoice = Invoice.order(:created_at).last
        expect(new_invoice.recipient).to be_nil
        expect(new_invoice.recipient_type).to be_nil
      end
    end

    it "is not allowed without show_details permission on the recipient" do
      allow(ability).to receive(:can?).and_call_original
      allow(ability).to receive(:can?).with(:show_details, recipient).and_return(false)

      expect {
        expect { instance.save }.to raise_error(CanCan::AccessDenied)
      }.not_to change { Invoice.count }
    end

    context "with an unknown recipient_id" do
      before { payload[:data][:attributes][:recipient_id] = Person.maximum(:id).next }

      it "is not valid" do
        expect {
          expect(instance.save).to eq(false)
        }.not_to change { Invoice.count }
        expect(instance.errors.full_messages).to include("Empfänger ist nicht gültig")
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
        expect(new_invoice.total).to eq(75.0)
      end

      it "fails when a sideposted invoice_item is invalid" do
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
      let(:token) { service_tokens(:permitted_bottom_layer_token) }
      let(:ability) { TokenAbility.new(token) }

      it "can create with finance permission" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { Invoice.count }.by(1)
        expect(Invoice.order(:created_at).last.creator).to be_nil
      end

      context "with layer_read permission" do
        let(:token) { super().tap { |t| t.update!(permission: :layer_read) } }

        it "cannot create" do
          expect { instance.save }.to raise_error(CanCan::AccessDenied)
        end
      end

      context "of a layer above" do
        let(:token) { service_tokens(:permitted_top_layer_token) }

        it "cannot create, as finance does not extend to sub-layers" do
          expect { instance.save }.to raise_error(CanCan::AccessDenied)
        end
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

    it "responds with the validation errors of an invalid invoice" do
      instance = InvoiceResource.find(payload(title: nil))
      expect {
        expect(instance.update_attributes).to eq(false)
      }.not_to change { invoice.reload.title }
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

      it "includes a new invoice item in the total" do
        attrs = payload.deep_merge(
          data: {
            relationships: {
              invoice_items: {
                data: [{"temp-id": -1, type: "invoice_items", method: "create"}]
              }
            }
          },
          included: [{
            "temp-id": -1,
            type: "invoice_items",
            attributes: {name: "pens - new", unit_cost: 10, count: 1}
          }]
        )
        instance = InvoiceResource.find(attrs)
        expect {
          expect(instance.update_attributes).to eq(true)
        }.to change { invoice.reload.total }.by(10)
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
