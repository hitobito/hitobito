# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PaymentsController do

  let(:group)   { groups(:bottom_layer_one) }
  let(:person)  { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }

  before { sign_in(person) }

  describe 'POST#create' do
    it 'valid arguments create payment' do
      invoice.update(state: :sent)
      expect do
        post :create, params: { group_id: group.id, invoice_id: invoice.id, payment: { amount: invoice.total } }
      end.to change { invoice.payments.count }.by(1)

      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(group_invoice_path(group, invoice))
    end

    it 'valid arguments create payment and updates invoice_list' do
      list = InvoiceList.create(title: :title, group: invoice.group)
      invoice.update(state: :sent, invoice_list: list)
      expect do
        post :create, params: { group_id: group.id, invoice_id: invoice.id, payment: { amount: invoice.total } }
      end.to change { invoice.payments.count }.by(1)

      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(group_invoice_path(group, invoice))
      expect(list.reload.recipients_paid).to eq 1
      expect(list.amount_paid).to eq invoice.total
    end

    it 'invalid arguments redirect back' do
      invoice.update(state: :sent)
      expect do
        post :create, params: { group_id: group.id, invoice_id: invoice.id, payment: { amount: '' } }
      end.not_to change { invoice.payments.count }
      expect(assigns(:payment)).to be_invalid
      expect(response).to redirect_to(group_invoice_path(group, invoice))
    end
  end

  describe 'GET#index' do
    let!(:payments) do
      5.times.map do
        Payment.create(amount: 20, invoice: invoice,
                       payee_attributes: { person_name: Faker::Name.name,
                                           person_address: Faker::Address.street_address })
      end
    end

    it 'lists payments' do
      get :index, params: { group_id: group.id, format: :csv }

      expect(assigns(:payments)).to match_array(payments)
    end

    it 'lists payments without invoice' do
      unassigned_payments = payments.sample(3).each { _1.update!(invoice_id: nil) }

      get :index, params: { group_id: group.id, format: :csv, state: :without_invoice }

      expect(assigns(:payments)).to match_array(unassigned_payments)
    end

    it 'lists payments in daterange' do
      daterange_payments = payments.sample(3).each { _1.update!(received_at: 1.year.ago) }

      get :index, params: { group_id: group.id, format: :csv, from: 1.year.ago.beginning_of_year, to: 1.year.ago.end_of_year }

      expect(assigns(:payments)).to match_array(daterange_payments)
    end
  end

end
