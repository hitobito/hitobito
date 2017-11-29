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

  before { sign_in(person) }

  it 'POST#creates valid arguments create payment_reminder' do
    invoice.update(state: :sent)
    expect do
      post :create, group_id: group.id, invoice_id: invoice.id,
        payment_reminder: { due_at: invoice.due_at + 2.weeks  }
    end.to change { invoice.payment_reminders.count }.by(1)

    expect(flash[:notice]).to be_present
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
  end

end
