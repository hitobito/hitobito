# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoices::ByArticleController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }
  before { sign_in(person) }

  context 'authorization' do
    it "may index when person has finance permission on layer group" do
      get :index, params: { group_id: group.id }
      expect(response).to be_successful
    end

    it "may not index when person has no finance permission on layer group" do
      expect do
        get :index, params: { group_id: groups(:top_layer).id }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'index' do
    it 'GET#index loads invoices with Payments::Collection#having_invoice_item' do
      from = 10.days.ago.to_date
      to = 5.days.ago.to_date
      name = 'some_name'
      cost_center = 'some_cost_center'
      account = 'some_account'

      invoice = Fabricate(:invoice, recipient_email: 'test@example.com', group: group)

      payments = stub('payments')
      expect(payments).to receive(:pluck).with(:invoice_id).and_return([invoice.id])

      payments_collection = instance_double(Payments::Collection)
      expect(Payments::Collection).to receive(:new).and_return(payments_collection)
      expect(payments_collection).to receive(:in_layer).with(group.id).and_return(payments_collection)
      expect(payments_collection).to receive(:from).with(from).and_return(payments_collection)
      expect(payments_collection).to receive(:to).with(to).and_return(payments_collection)
      expect(payments_collection).to receive(:having_invoice_item).with(name, account, cost_center)
                                                                  .and_return(payments_collection)
      allow(payments_collection).to receive(:payments).and_return(payments)

      get :index, params: {
        group_id: group.id,
        from: from.to_json,
        to: to.to_json,
        name: name,
        cost_center: cost_center,
        account: account
      }

      expect(assigns(:invoices)).to match_array([invoice])
    end
  end
end
