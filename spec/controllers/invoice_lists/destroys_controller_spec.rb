# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceLists::DestroysController do
  let(:layer) { groups(:top_layer) }

  let(:draft_invoices) do
    [0..10].map do
      Fabricate(:invoice, due_at: 10.days.from_now, creator: people(:top_leader), state: :draft, recipient: people(:bottom_member), group: layer)
    end
  end

  let(:invoice_list) { InvoiceList.create(title: 'membership fee', invoices: draft_invoices, group: layer) }

  let(:params) { { group_id: layer.id, invoice_list_id: invoice_list.id } }
  before { sign_in(user) }

  context 'DELETE#destroy' do
    context 'without finance permission' do
      let(:user) { Fabricate(Group::TopLayer::TopAdmin.sti_name.to_sym, group: layer).person }

      it 'is unauthorized' do
        expect do
          delete :destroy, params: params
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'with finance permission in different layer' do
      let(:user) { people(:bottom_member) }

      it 'is unauthorized' do
        expect do
          delete :destroy, params: params
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'with finance permission in same layer' do
      let(:user) { people(:top_leader) }

      context 'for invoice list with only draft invoices' do
        it 'deletes invoice_list' do
          expect(InvoiceList.exists?(invoice_list.id)).to be(true)

          expect do
            delete :destroy, params: params
          end.to change { InvoiceList.count }.by(-1)

          expect(InvoiceList.exists?(invoice_list.id)).to be(false)
        end
      end

      context 'for invoice list with not only draft invoices' do
        before { draft_invoices.sample.update(state: :sent) }

        it 'raises error' do
          expect do
            delete :destroy, params: params
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
