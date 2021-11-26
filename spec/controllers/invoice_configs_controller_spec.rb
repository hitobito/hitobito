# encoding: utf-8

#  Copyright (c) 2017-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceConfigsController  do

  let(:group)  { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:entry)  { invoice_configs(:bottom_layer_one) }

  before { sign_in(person) }

  context 'authorization' do
    it "may show when person has finance permission on layer group" do
      get :show, params: { group_id: group.id, id: entry.id }
      expect(response).to be_successful
    end

    it "may edit when person has finance permission on layer group" do
      get :edit, params: { group_id: group.id, id: entry.id }
      expect(response).to be_successful
    end

    it "may not show when person has finance permission on layer group" do
      expect do
        get :show, params: { group_id: groups(:top_layer).id, id: invoice_configs(:top_layer).id }
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        get :edit, params: { group_id: groups(:top_layer).id, id: invoice_configs(:top_layer).id }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context  'GET edit' do
    it "initializes 3 valid payment reminder configs if none are set" do
      get :edit, params: { group_id: group.id, id: entry.id }
      expect(assigns(:invoice_config).payment_reminder_configs).to have(3).items
      assigns(:invoice_config).payment_reminder_configs.each do |config|
        expect(config).to be_valid
      end
    end

    it "initializes payment provider config if none is present" do
      configured_payment_providers = Settings.payment_providers
      expect(configured_payment_providers.size).to be_positive

      get :edit, params: { group_id: group.id, id: entry.id }

      expect(assigns(:invoice_config).payment_provider_configs.size)
        .to eq(configured_payment_providers.size)

      assigns(:invoice_config).payment_provider_configs.each do |config|
        expect(config).to be_valid
      end
    end
  end

  context 'PATCH update' do
    it "creates 3 payment reminder configs" do
      attrs = 1.upto(3).collect do |level|
        [level.to_s, { title: level, level: level, text: level, due_days: level }]
      end.to_h

      expect do
        patch :update, params: { group_id: group.id, invoice_config: {
          payment_reminder_configs_attributes: attrs
        } }
      end.to change { entry.reload.payment_reminder_configs.size }.by(3)
    end

    it 'creates a payment provider config but does not setup ebics if required values are not present' do
      attrs = { 0 => { payment_provider: 'postfinance' } }

      expect(PaymentProvider).to_not receive(:new)

      expect do
        patch :update, params: { group_id: group.id, invoice_config: {
          payment_provider_configs_attributes: attrs }
        }
      end.to change { entry.reload.payment_provider_configs.size }.by(1)
    end

    it 'creates a payment provider config and sets up ebics if required values are present' do
      attrs = { 0 => { payment_provider: 'postfinance',
                       password: 'password',
                       partner_identifier: 'EPF0002',
                       user_identifier: 'ACE2004' } }

      provider = double

      expect(PaymentProvider).to receive(:new).and_return(provider)
      expect(provider).to receive(:initial_setup).exactly(:once)
      expect(provider).to receive(:INI).exactly(:once)
      expect(provider).to receive(:HIA).exactly(:once)

      expect do
        patch :update, params: { group_id: group.id, id: entry.id, invoice_config: {
          payment_provider_configs_attributes: attrs
        } }
      end.to change { entry.reload.payment_provider_configs.size }.by(1)
    end

    it 'sets flash message on ebics initialization error' do
      attrs = { 0 => { payment_provider: 'postfinance',
                       password: 'password',
                       partner_identifier: 'EPF0002',
                       user_identifier: 'ACE2004' } }

      provider = double

      expect(PaymentProvider).to receive(:new).and_return(provider)
      expect(provider).to receive(:initial_setup).exactly(:once)
      expect(provider).to receive(:INI).exactly(:once)
      expect(provider).to receive(:HIA).exactly(:once).and_raise(Ebics::Error::TechnicalError.new('091002'))

      expect do
        patch :update, params: { group_id: group.id, id: entry.id, invoice_config: {
          payment_provider_configs_attributes: attrs
        } }
      end.to change { entry.reload.payment_provider_configs.size }.by(1)
      expect(flash[:alert]).to match(/Einrichten der Zahlungsschnittstelle Postfinance ist fehlgeschlagen/)
    end
  end
end

