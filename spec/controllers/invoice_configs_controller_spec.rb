# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceConfigsController  do

  let(:group)  { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:entry)  { invoice_configs(:bottom_layer_one) }

  context 'authorization' do
    before { sign_in(person) }

    it "may show when person has finance permission on layer group" do
      get :show, group_id: group.id, id: entry.id
      expect(response).to be_success
    end

    it "may edit when person has finance permission on layer group" do
      get :edit, group_id: group.id, id: entry.id
      expect(response).to be_success
    end

    it "may not show when person has finance permission on layer group" do
      expect do
        get :show, group_id: groups(:top_layer).id, id: invoice_configs(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        get :edit, group_id: groups(:top_layer).id, id: invoice_configs(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end

