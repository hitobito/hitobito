# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaymentsController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }

  before { sign_in(person) }

  it "POST#creates valid arguments create payment" do
    invoice.update(state: :sent)
    expect do
      post :create, params: {group_id: group.id, invoice_id: invoice.id, payment: {amount: invoice.total}}
    end.to change { invoice.payments.count }.by(1)

    expect(flash[:notice]).to be_present
    expect(response).to redirect_to(group_invoice_path(group, invoice))
  end

  it "POST#creates valid arguments create payment and updates invoice_list" do
    list = InvoiceList.create(title: :title, group: invoice.group)
    invoice.update(state: :sent, invoice_list: list)
    expect do
      post :create, params: {group_id: group.id, invoice_id: invoice.id, payment: {amount: invoice.total}}
    end.to change { invoice.payments.count }.by(1)

    expect(flash[:notice]).to be_present
    expect(response).to redirect_to(group_invoice_path(group, invoice))
    expect(list.reload.recipients_paid).to eq 1
    expect(list.amount_paid).to eq invoice.total
  end

  it "POST#creates invalid arguments redirect back" do
    invoice.update(state: :sent)
    expect do
      post :create, params: {group_id: group.id, invoice_id: invoice.id, payment: {amount: ""}}
    end.not_to change { invoice.payments.count }
    expect(assigns(:payment)).to be_invalid
    expect(response).to redirect_to(group_invoice_path(group, invoice))
  end
end
