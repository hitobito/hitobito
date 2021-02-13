# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceConfigsController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:entry) { invoice_configs(:bottom_layer_one) }

  context "authorization" do
    before { sign_in(person) }

    it "may show when person has finance permission on layer group" do
      get :show, params: {group_id: group.id, id: entry.id}
      expect(response).to be_successful
    end

    it "may edit when person has finance permission on layer group" do
      get :edit, params: {group_id: group.id, id: entry.id}
      expect(response).to be_successful
    end

    it "may not show when person has finance permission on layer group" do
      expect do
        get :show, params: {group_id: groups(:top_layer).id, id: invoice_configs(:top_layer).id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        get :edit, params: {group_id: groups(:top_layer).id, id: invoice_configs(:top_layer).id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "initializes 3 valid payment reminder configs if non are set" do
      get :edit, params: {group_id: group.id, id: entry.id}
      expect(assigns(:invoice_config).payment_reminder_configs).to have(3).items
      assigns(:invoice_config).payment_reminder_configs.each do |config|
        expect(config).to be_valid
      end
    end

    it "creates 3 payment reminder configs" do
      attrs = 1.upto(3).collect do |level|
        [level.to_s, {title: level, level: level, text: level, due_days: level}]
      end.to_h
      expect do
        patch :update, params: {group_id: group.id, id: entry.id, invoice_config: {
          payment_reminder_configs_attributes: attrs
        }}
      end.to change { entry.reload.payment_reminder_configs.size }.by(3)
    end
  end
end
