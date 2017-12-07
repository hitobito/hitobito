# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PaymentRemindersController do

  let(:group)   { groups(:bottom_layer_one) }
  let(:person)  { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }
  let(:sent)    { invoices(:sent) }

  before { sign_in(person) }

  context 'invoice' do

    it 'POST#creates valid arguments create payment_reminder' do
      invoice.update(state: :sent)
      expect do
        post :create, group_id: group.id, invoice_id: invoice.id,
          payment_reminder: { due_at: invoice.due_at + 2.weeks  }
      end.to change { invoice.payment_reminders.count }.by(1)

      expect(flash[:notice]).to eq 'Zahlungserinnerung wurde erfasst.'
      expect(response).to redirect_to(group_invoice_path(group, invoice))
    end

    it 'POST#creates invalid arguments redirect back' do
      invoice.update(state: :sent)
      expect do
        post :create, group_id: group.id, invoice_id: invoice.id,
          payment_reminder: { due_at: invoice.due_at }
      end.not_to change { invoice.payment_reminders.count }
      expect(assigns(:payment_reminder)).to be_invalid
      expect(response).to redirect_to(group_invoice_path(group, invoice))
      expect(flash[:alert]).to match 'Fällig am muss '
    end
  end

  context 'invoice list' do
    it 'POST#creates ignores invalid invoices' do
      sent.update(group: groups(:top_layer))
      expect do
        post :create, group_id: group.id,
          payment_reminder: { message: 'hello', ids: "#{invoice.id},#{sent.id}"}
      end.not_to change { PaymentReminder.count }

      expect(flash[:alert]).to be_present
      expect(flash[:alert]).to eq 'Es wurden keine gültigen Rechnungen ausgewählt.'
      expect(response).to redirect_to(group_invoices_path(group))
    end
    it 'POST#creates valid arguments create payment_reminder' do
      invoice.update(state: :sent)
      expect do
        post :create, group_id: group.id,
          payment_reminder: { message: 'hello', ids: "#{invoice.id},#{sent.id}"}
      end.to change { PaymentReminder.count }.by(2)

      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to eq '2 Zahlungserinnerungen wurden erfasst.'
      expect(response).to redirect_to(group_invoices_path(group))
    end
  end

end
