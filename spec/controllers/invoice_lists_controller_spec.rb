# frozen_string_literal: true

require 'spec_helper'

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

describe InvoiceListsController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  context 'authorization' do
    before { sign_in(person) }

    it "may index when person has finance permission on layer group" do
      get :new, params: { group_id: group.id, invoice: { recipient_ids: [person.id] } }
      expect(response).to be_successful
    end

    it "may update when person has finance permission on layer group" do
      put :update, params: { group_id: group.id, invoice: { recipient_ids: [] } }
      expect(response).to redirect_to group_invoices_path(group)
    end

    it "may not index when person has finance permission on layer group" do
      expect do
        get :new, params: { group_id: groups(:top_layer).id, invoice: { recipient_ids: [] } }
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        put :update, params: { group_id: groups(:top_layer).id, invoice: { recipient_ids: [] } }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'authorized' do
    include ActiveSupport::Testing::TimeHelpers

    before { sign_in(person) }

    it 'GET#new assigns_attributes and renders crud/new template' do
      get :new, params: { group_id: group.id, invoice: { recipient_ids: person.id } }
      expect(response).to render_template('crud/new')
      expect(assigns(:invoice).recipients).to eq [person]
    end

    it 'GET#new via xhr assigns invoice items and total' do
      get :new, xhr: true, params: { group_id: group.id, invoice: invoice_attrs }
      expect(assigns(:invoice).invoice_items).to have(2).items
      expect(assigns(:invoice).calculated[:total]).to eq 3
      expect(response).to render_template('invoice_lists/new')
    end

    it 'POST#create creates an invoice for single member' do
      expect do
        post :create, params: { group_id: group.id, invoice: invoice_attrs.merge(recipient_ids: person.id) }
      end.to change { group.invoices.count }.by(1)

      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to include 'Rechnung <i>Title</i> wurde erstellt.'
    end

    it 'POST#create sets creator_id to current_user' do
      expect do
        post :create, params: { group_id: group.id, invoice: invoice_attrs.merge(title: 'current_user') }
      end.to change { group.invoices.count }.by(1)

      expect(Invoice.find_by(title: 'current_user').creator).to eq(person)
    end

    it 'POST#create creates an invoice for each member of group' do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group, person: Fabricate(:person))

      expect do
        post :create, params: { group_id: group.id, invoice: invoice_attrs }
      end.to change { group.invoices.count }.by(2)

      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to include 'Rechnung <i>Title</i> wurde für 2 Empfänger erstellt.'
    end

    it 'PUT#update informs if not invoice has been selected' do
      post :update, params: { group_id: group.id }
      expect(response).to redirect_to group_invoices_path(group)
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
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice][0]).to match /Rechnung \d+-\d+ wurde gestellt./
      expect(invoice.reload.state).to eq 'issued'
      expect(invoice.due_at).to be_present
      expect(invoice.issued_at).to be_present
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
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to include '2 Rechnungen wurden gestellt.'
    end

    it 'PUT#update enqueues job' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person,
                                invoice_items_attributes:
                                  { '1' => { name: 'item1', unit_cost: 1, count: 1}})

      expect do
        post :update, params: { group_id: group.id, ids: [invoice.id].join(','), mail: 'true' }
      end.to change { Delayed::Job.count }.by(1)

      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice][0]).to match(/Rechnung \d+-\d+ wurde gestellt./)
      expect(flash[:notice][1]).to match(/Rechnung \d+-\d+ wird im Hintergrund per E-Mail verschickt./)
    end

    it 'DELETE#destroy informs if no invoice has been selected' do
      delete :destroy, params: { group_id: group.id }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:alert]).to include 'Zuerst muss eine Rechnung ausgewählt werden.'
    end

    it 'DELETE#destroy moves invoice to cancelled state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        travel(1.day) { delete :destroy, params: { group_id: group.id, ids: invoice.id } }
      end.to change { invoice.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group)
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
      expect(response).to redirect_to group_invoices_path(group)
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
