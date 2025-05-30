# frozen_string_literal: true

require "spec_helper"

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

describe InvoiceListsController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:list) { mailing_lists(:leaders) }

  context "authorization" do
    before { sign_in(person) }

    it "may new when person has finance permission on layer group" do
      get :new, params: {group_id: group.id, invoice_list: {recipient_ids: person.id}}
      expect(response).to be_successful
      expect(assigns(:invoice_list)).to have(1).recipient
    end

    it "may update when person has finance permission on layer group" do
      put :update, params: {group_id: group.id, invoice_list: {recipient_ids: ""}}
      expect(response).to redirect_to group_invoices_path(group, returning: true)
    end

    it "may not index when person has no finance permission on layer group" do
      expect do
        get :new, params: {group_id: groups(:top_layer).id, invoice_list: {recipient_ids: ""}}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        put :update, params: {group_id: groups(:top_layer).id, invoice_list: {recipient_ids: ""}}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "index" do
    render_views
    let(:group) { groups(:top_layer) }
    let(:node) { Capybara::Node::Simple.new(response.body) }
    let(:column) { node.find("#main table tbody tr td:eq(3)") }

    before { sign_in(people(:top_leader)) }

    it "renders final Empfänger count" do
      InvoiceList.create!(group: group, title: "title", recipients_processed: 20, recipients_total: 20)
      get :index, params: {group_id: group.id}
      expect(column).to have_text("20")
    end
  end

  context "parameter handling" do
    before { sign_in(person) }

    it "ignores empty ids param" do
      get :new,
        params: {
          group_id: group.id,
          invoice_list: {recipient_ids: person.id},
          ids: ""
        }

      expect(response).to be_successful
      expect(assigns(:invoice_list)).to have(1).recipients
    end

    it "values from ids param as passed by checkable override recipient_ids" do
      get :new,
        params: {
          group_id: group.id,
          invoice_list: {recipient_ids: person.id},
          ids: "#{person.id},#{people(:top_leader).id}"
        }

      expect(response).to be_successful
      expect(assigns(:invoice_list)).to have(2).recipients
    end

    it "values from filter param" do
      leader = Fabricate(Group::BottomLayer::Leader.sti_name, group: group).person
      role_types = [Group::BottomLayer::Leader]

      get :new,
        params: {
          group_id: group.id,
          invoice_list: {recipient_ids: person.id},
          filter: {
            group_id: group.id,
            range: "deep",
            filters: {
              role: {role_type_ids: role_types.collect(&:id).join("-")}
            }
          }
        }

      expect(response).to be_successful
      expect(assigns(:invoice_list)).to have(1).recipients
      expect(assigns(:invoice_list).recipients).to eq([leader])
    end

    it "handles blank filter params" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: group)

      get :new,
        params: {
          group_id: group.id,
          invoice_list: {recipient_ids: person.id},
          filter: {
            group_id: group.id,
            range: "",
            filters: ""
          }
        }

      expect(response).to be_successful
      expect(assigns(:invoice_list)).to have(2).recipients
    end
  end

  context "sheet title" do
    before { sign_in(person) }

    let(:sheet_title) { Capybara::Node::Simple.new(response.body).find(".content-header") }

    render_views

    it "renders Sammelrechnung title for single person" do
      get :new,
        params: {
          group_id: group.id,
          invoice_list: {recipient_ids: person.id},
          ids: ""
        }

      expect(sheet_title).to have_text "Sammelrechnung"
    end

    it "renders Sammelrechnung title for multiple people" do
      get :new,
        params: {
          group_id: group.id,
          invoice_list: {recipient_ids: "#{person.id},#{people(:top_leader).id}"},
          ids: ""
        }

      expect(sheet_title).to have_text "Sammelrechnung"
    end

    it "renders Sammelrechnung title for abo" do
      get :new,
        params: {
          group_id: group.id,
          invoice_list: {receiver_id: list.id, receiver_type: list.class}
        }

      expect(sheet_title).to have_text "Sammelrechnung"
    end
  end

  context "authorized" do
    before { sign_in(person) }

    it "GET#new assigns_attributes and renders crud/new template" do
      get :new, params: {group_id: group.id, invoice_list: {recipient_ids: person.id}}
      expect(response).to render_template("crud/new")
      expect(assigns(:invoice_list).recipients).to eq [person]
    end

    it "GET#new assigns invoice_list from receiver" do
      get :new, params: {group_id: group.id, invoice_list: {receiver_id: list.id, receiver_type: list.class}}
      expect(response).to render_template("crud/new")
      expect(assigns(:invoice_list).receiver).to eq list
    end

    it "GET#new assigns payment_information from invoice_config" do
      group.invoice_config.update(payment_information: "Bitte schnellstmöglich einzahlen")

      get :new, params: {group_id: group.id, invoice_list: {receiver_id: list.id, receiver_type: list.class}}
      expect(response).to render_template("crud/new")
      expect(assigns(:invoice_list).invoice.payment_information).to eq "Bitte schnellstmöglich einzahlen"
    end

    it "GET#new prepares membership invoice" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      get :new, params: {group_id: group.id, fixed_fees: :membership}
      expect(response).to render_template("crud/new")

      members, leaders = assigns(:invoice_list).invoice.invoice_items
      expect(members.name).to eq "Mitgliedsbeitrag - Members"
      expect(leaders.name).to eq "Mitgliedsbeitrag - Leaders"
      expect(members.count).to eq 1
      expect(leaders.count).to eq 1
    end

    it "POST#create creates an invoice for single member" do
      expect do
        post :create, params: {group_id: group.id, invoice_list: {recipient_ids: person.id, invoice: invoice_attrs}}
      end.to change { group.invoices.count }.by(1)

      expect(response).to redirect_to group_invoice_list_invoices_path(group, InvoiceList.last, returning: true)
      expect(flash[:notice]).to include "Rechnung <i>Title</i> wurde erstellt."
    end

    it "POST#create sets creator_id to current_user" do
      expect do
        post :create, params: {group_id: group.id, invoice_list: {recipient_ids: person.id, invoice: invoice_attrs.merge(title: "current_user")}}
      end.to change { group.invoices.count }.by(1)

      expect(Invoice.find_by(title: "current_user").creator).to eq(person)
    end

    it "POST#create for mailing list receiver redirects to invoice_lists page" do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      expect do
        post :create, params: {group_id: group.id, invoice_list: {receiver_id: list.id, receiver_type: list.class, invoice: invoice_attrs.merge(title: "test")}}
      end.to change { group.invoices.count }.by(1)
      expect(assigns(:invoice_list).receiver).to eq list
      expect(response).to redirect_to group_invoice_lists_path(group)
    end

    it "POST#create for group receiver redirects to invoice_lists page" do
      expect do
        post :create, params: {group_id: group.id, invoice_list: {receiver_id: group.id, receiver_type: group.class.base_class, invoice: invoice_attrs.merge(title: "test")}}
      end.to change { group.invoices.count }.by(1)
      expect(assigns(:invoice_list).receiver).to eq group
      expect(response).to redirect_to group_invoice_lists_path(group)
    end

    it "POST#create an invoice in background" do
      stub_const("InvoiceListsController::LIMIT_CREATE", 2)
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      Subscription.create!(mailing_list: list, subscriber: groups(:bottom_layer_one), role_types: [Group::BottomLayer::Member])
      expect do
        post :create, params: {group_id: group.id, invoice_list: {receiver_id: list.id, receiver_type: list.class, invoice: invoice_attrs.merge(title: "test")}}
        Delayed::Job.last.payload_object.perform
      end.to change { group.invoices.count }.by(2)

      expect(flash[:notice]).to include "Rechnung <i>test</i> wird für 2 Empfänger im Hintergrund erstellt."
      expect(response).to redirect_to group_invoice_lists_path(group)
    end

    it "PUT#update informs if not invoice has been selected" do
      post :update, params: {group_id: group.id}
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:alert]).to include "Es muss mindestens eine Rechnung ausgewählt werden."
    end

    it "PUT#update moves invoice to sent state" do
      invoice = Invoice.create!(group: group, title: "test", recipient: person,
        invoice_items_attributes:
          {"1" => {name: "item1", unit_cost: 1, count: 1}})
      travel(1.day) do
        expect do
          expect do
            post :update, params: {group_id: group.id, ids: invoice.id}
          end.to change { invoice.reload.updated_at }
        end.not_to change { Delayed::Job.count }
      end
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice][0]).to match(/Rechnung \d+-\d+ wurde gestellt./)
      expect(invoice.reload.state).to eq "issued"
      expect(invoice.due_at).to be_present
      expect(invoice.issued_at).to be_present
    end

    it "PUT#update redirects to invoice_list_invoices path if invoice_list is set" do
      list = InvoiceList.create!(title: :title, group: group)
      invoice = Invoice.create!(group: group, title: "test", recipient: person,
        invoice_list: list,
        invoice_items_attributes:
          {"1" => {name: "item1", unit_cost: 1, count: 1}})
      post :update, params: {group_id: group.id, invoice_list_id: list.id, ids: invoice.id}
      expect(response).to redirect_to group_invoice_list_invoices_path(group, list, returning: true)
    end

    it "PUT#update redirects to invoice_list_invoice path if invoice_list is set and singular is true" do
      list = InvoiceList.create!(title: :title, group: group)
      invoice = Invoice.create!(group: group, title: "test", recipient: person,
        invoice_list: list,
        invoice_items_attributes:
          {"1" => {name: "item1", unit_cost: 1, count: 1}})
      post :update, params: {group_id: group.id, invoice_list_id: list.id, ids: invoice.id, singular: true}
      expect(response).to redirect_to group_invoice_list_invoice_path(group, list, invoice)
    end

    it "PUT#update can move multiple invoices at once" do
      invoice = Invoice.create!(group: group, title: "test", recipient: person,
        invoice_items_attributes:
          {"1" => {name: "item1", unit_cost: 1, count: 1}})

      other = Invoice.create!(group: group, title: "test", recipient: person,
        invoice_items_attributes:
          {"1" => {name: "item1", unit_cost: 1, count: 1}})
      travel(1.day) do
        expect do
          post :update, params: {group_id: group.id, ids: [invoice.id, other.id].join(",")}
        end.to change { other.reload.updated_at }
      end
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice]).to include "2 Rechnungen wurden gestellt."
    end

    it "PUT#update enqueues job" do
      invoice = Invoice.create!(group: group, title: "test", recipient: person,
        invoice_items_attributes:
          {"1" => {name: "item1", unit_cost: 1, count: 1}})

      expect do
        post :update, params: {group_id: group.id, ids: [invoice.id].join(","), mail: "true"}
      end.to change { Delayed::Job.count }.by(1)

      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice][0]).to match(/Rechnung \d+-\d+ wurde gestellt./)
      expect(flash[:notice][1]).to match(/Rechnung \d+-\d+ wird im Hintergrund per E-Mail verschickt./)
    end

    describe "DELETE#destroy" do
      it "informs if no invoice has been selected" do
        delete :destroy, params: {group_id: group.id}
        expect(response).to redirect_to group_invoices_path(group, returning: true)
        expect(flash[:alert]).to include "Zuerst muss eine Rechnung ausgewählt werden."
      end

      it "moves invoice to cancelled state" do
        invoice = Invoice.create!(group: group, title: "test", recipient: person)
        expect do
          travel(1.day) { delete :destroy, params: {group_id: group.id, ids: invoice.id} }
        end.to change { invoice.reload.updated_at }
        expect(response).to redirect_to group_invoices_path(group, returning: true)
        expect(flash[:notice]).to include "Rechnung wurde storniert."
        expect(invoice.reload.state).to eq "cancelled"
      end

      it "may move multiple invoices to cancelled state" do
        invoice = Invoice.create!(group: group, title: "test", recipient: person)
        other = Invoice.create!(group: group, title: "test", recipient: person)
        expect do
          travel 1.day do
            delete :destroy, params: {group_id: group.id, ids: [invoice.id, other.id].join(",")}
          end
        end.to change { other.reload.updated_at }
        expect(response).to redirect_to group_invoices_path(group, returning: true)
        expect(flash[:notice]).to include "2 Rechnungen wurden storniert."
        expect(other.reload.state).to eq "cancelled"
      end

      it "redirects to list and updates total" do
        invoice_list = InvoiceList.create!(title: "test", group: group)
        invoice = Invoice.create!(group: group, title: "test", recipient: person, invoice_list: invoice_list)
        invoice.invoice_items.create!(name: :pens, count: 2, unit_cost: 10)

        other = Invoice.create!(group: group, title: "test", recipient: person, invoice_list: invoice_list)
        other.invoice_items.create!(name: :pens, count: 1, unit_cost: 10)
        invoice_list.update_total
        invoice_list.invoices.each(&:recalculate!)

        expect do
          travel(1.day) { delete :destroy, params: {group_id: group.id, invoice_list_id: invoice_list.id, ids: invoice.id} }
        end.to change { invoice.reload.updated_at }
          .and change { invoice_list.reload.amount_total }.from(30).to(10)
        expect(response).to redirect_to group_invoice_list_invoices_path(group, invoice_list, returning: true)
      end
    end
  end

  def invoice_attrs
    {
      title: "Title",
      recipient_ids: group.people.limit(2).collect(&:id).join(","),
      invoice_items_attributes: {"1" => {name: "item1", unit_cost: 1, count: 1},
                                 "2" => {name: "item2", unit_cost: 2, count: 1}}
    }
  end
end
