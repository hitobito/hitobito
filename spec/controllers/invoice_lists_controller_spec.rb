# frozen_string_literal: true

require 'spec_helper'

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

describe InvoiceListsController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:list) { mailing_lists(:leaders) }

  context 'authorization' do
    before { sign_in(person) }

    it "may new when person has finance permission on layer group" do
      get :new, params: { group_id: group.id, invoice_list: { recipient_ids: [person.id] } }
      expect(response).to be_successful
    end

    it "may update when person has finance permission on layer group" do
      put :update, params: { group_id: group.id, invoice_list: { recipient_ids: [] } }
      expect(response).to redirect_to group_invoices_path(group, returning: true)
    end

    it "may not index when person has finance permission on layer group" do
      expect do
        get :new, params: { group_id: groups(:top_layer).id, invoice_list: { recipient_ids: [] } }
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        put :update, params: { group_id: groups(:top_layer).id, invoice_list: { recipient_ids: [] } }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'authorized' do
    before { sign_in(person) }

    it 'GET#new assigns_attributes and renders crud/new template' do
      get :new, params: { group_id: group.id, invoice_list: { recipient_ids: person.id } }
      expect(response).to render_template('crud/new')
      expect(assigns(:invoice_list).recipients).to eq [person]
    end

    it 'GET#new assigns assigns invoice_list from receiver' do
      get :new, params: { group_id: group.id, invoice_list: { receiver_id: list.id, receiver_type: list.class  } }
      expect(response).to render_template('crud/new')
      expect(assigns(:invoice_list).receiver).to eq list
    end

    it 'GET#new via xhr assigns invoice items and total' do
      get :new, xhr: true, params: { group_id: group.id, invoice_list: { invoice: invoice_attrs } }
      invoice = assigns(:invoice_list).invoice
      expect(invoice.invoice_items).to have(2).items
      expect(invoice.calculated[:total]).to eq 3
      expect(response).to render_template('invoice_lists/new')
    end

    it 'POST#create creates an invoice for single member' do
      expect do
        post :create, params: { group_id: group.id, invoice_list: { recipient_ids: person.id, invoice: invoice_attrs } }
      end.to change { group.invoices.count }.by(1)

      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice]).to include 'Rechnung <i>Title</i> wurde erstellt.'
    end

    it 'POST#create sets creator_id to current_user' do
      expect do
        post :create, params: { group_id: group.id, invoice_list: { recipient_ids: person.id, invoice: invoice_attrs.merge(title: 'current_user')  }}
      end.to change { group.invoices.count }.by(1)

      expect(Invoice.find_by(title: 'current_user').creator).to eq(person)
    end

    it 'POST#create for receiver redirects to invoice_lists page' do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      expect do
        post :create, params: { group_id: group.id, invoice_list: { receiver_id: list.id, receiver_type: list.class, invoice: invoice_attrs.merge(title: 'test') } }
      end.to change { group.invoices.count }.by(1)
      expect(assigns(:invoice_list).receiver).to eq list
      expect(response).to redirect_to group_invoice_lists_path(group)
    end

    it 'PUT#update informs if not invoice has been selected' do
      post :update, params: { group_id: group.id }
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:alert]).to include 'Es muss mindestens eine Rechnung ausgewählt werden.'
    end

    it 'PUT#update moves invoice to sent state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person,
                                invoice_items_attributes:
                                  { '1' => { name: 'item1', unit_cost: 1, count: 1}})
      travel(1.day) do
        expect do
          expect do
            post :update, params: { group_id: group.id, ids: invoice.id }
          end.to change { invoice.reload.updated_at }
        end.not_to change { Delayed::Job.count }
      end
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice][0]).to match /Rechnung \d+-\d+ wurde gestellt./
      expect(invoice.reload.state).to eq 'issued'
      expect(invoice.due_at).to be_present
      expect(invoice.issued_at).to be_present
    end

    it 'PUT#update redirects to invoice_list_invoices path if invoice_list is set' do
      list = InvoiceList.create!(title: :title, group: group)
      invoice = Invoice.create!(group: group, title: 'test', recipient: person,
                                invoice_list: list,
                                invoice_items_attributes:
                                  { '1' => { name: 'item1', unit_cost: 1, count: 1}})
      post :update, params: { group_id: group.id, invoice_list_id: list.id, ids: invoice.id }
      expect(response).to redirect_to group_invoice_list_invoices_path(group, list, returning: true)
    end

    it 'PUT#update can move multiple invoices at once' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person,
                                invoice_items_attributes:
                                  { '1' => { name: 'item1', unit_cost: 1, count: 1}})

      other = Invoice.create!(group: group, title: 'test', recipient: person,
                              invoice_items_attributes:
                                { '1' => { name: 'item1', unit_cost: 1, count: 1}})
      travel(1.day) do
        expect do
          post :update, params: { group_id: group.id, ids: [invoice.id, other.id].join(',') }
        end.to change { other.reload.updated_at }
      end
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice]).to include '2 Rechnungen wurden gestellt.'
    end

    it 'PUT#update enqueues job' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person,
                                invoice_items_attributes:
                                  { '1' => { name: 'item1', unit_cost: 1, count: 1}})

      expect do
        post :update, params: { group_id: group.id, ids: [invoice.id].join(','), mail: 'true' }
      end.to change { Delayed::Job.count }.by(1)

      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice][0]).to match(/Rechnung \d+-\d+ wurde gestellt./)
      expect(flash[:notice][1]).to match(/Rechnung \d+-\d+ wird im Hintergrund per E-Mail verschickt./)
    end

    it 'DELETE#destroy informs if no invoice has been selected' do
      delete :destroy, params: { group_id: group.id }
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:alert]).to include 'Zuerst muss eine Rechnung ausgewählt werden.'
    end

    it 'DELETE#destroy moves invoice to cancelled state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        travel(1.day) { delete :destroy, params: { group_id: group.id, ids: invoice.id } }
      end.to change { invoice.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice]).to include 'Rechnung wurde storniert.'
      expect(invoice.reload.state).to eq 'cancelled'
    end

    it 'DELETE#destroy may move multiple invoices to cancelled state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      other = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        travel 1.day do
          delete :destroy, params: { group_id: group.id, ids: [invoice.id, other.id].join(',') }
        end
      end.to change { other.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice]).to include '2 Rechnungen wurden storniert.'
      expect(other.reload.state).to eq 'cancelled'
    end
  end

  def invoice_attrs
    {
      title: 'Title',
      recipient_ids: group.people.limit(2).collect(&:id).join(','),
      invoice_items_attributes: { '1' => { name: 'item1', unit_cost: 1, count: 1},
                                  '2' => { name: 'item2', unit_cost: 2, count: 1 } }
    }
  end
end
