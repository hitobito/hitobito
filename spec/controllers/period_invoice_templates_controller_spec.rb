#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplatesController do
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }

  before do
    sign_in(people(:top_leader))
  end

  context "feature gate enabled" do
    around do |example|
      original = Settings.groups.period_invoice_templates.enabled
      Settings.groups.period_invoice_templates.enabled = true
      Rails.application.reload_routes!
      example.run
      Settings.groups.period_invoice_templates.enabled = original
      Rails.application.reload_routes!
    end

    it "GET#index does list period invoice templates" do
      get :index, params: {group_id: Group.root.id}
      expect(assigns(:period_invoice_templates)).to include(period_invoice_template)
    end

    it "POST#create creates a new period invoice template" do
      start = Time.zone.today
      expect do
        post :create, params: {
          group_id: Group.root.id,
          period_invoice_template: {
            name: "Test",
            start_on: start,
            recipient_group_type: Group::BottomLayer.name,
            items_attributes: {
              "0": {
                name: "Invoice item",
                type: PeriodInvoiceTemplate::RoleCountItem.name,
                dynamic_cost_parameters: {
                  unit_cost: 10,
                  role_types: [Group::BottomLayer::Member.name]
                }
              }
            }
          }
        }
      end.to change { PeriodInvoiceTemplate.count }.by 1
      expect(flash[:notice]).to eq "Sammelrechnung <i>Test</i> wurde erfolgreich erstellt."
      entry = PeriodInvoiceTemplate.last
      expect(entry.recipient_source_type).to eq GroupsFilter.name
      expect(entry.recipient_source.group_type).to eq Group::BottomLayer.name
      expect(entry.recipient_source.active_at).to eq start
      expect(entry.recipient_source.parent_id).to eq Group.root.id
    end

    it "POST#create validates inputs" do
      expect do
        post :create, params: {
          group_id: Group.root.id,
          period_invoice_template: {
            # name: "Test",
            # start_on: Time.zone.now,
            # recipient_group_type: Group::BottomLayer.name,
            items_attributes: {
              "0": {
                # name: "Invoice item",
                type: PeriodInvoiceTemplate::RoleCountItem.name,
                dynamic_cost_parameters: {
                  # unit_cost: 10,
                  # role_types: [Group::BottomLayer::Member.name]
                }
              }
            }
          }
        }
      end.not_to change { PeriodInvoiceTemplate.count }
      period_invoice_template = assigns(:period_invoice_template)
      expect(period_invoice_template).not_to be_valid
      expect(period_invoice_template.errors.messages).to eq({
        name: ["muss ausgefüllt werden"],
        start_on: ["muss ausgefüllt werden"],
        recipient_group_type: ["muss ausgefüllt werden", "ist kein gültiger Wert"],
        "items.name": ["muss ausgefüllt werden"],
        "items.unit_cost": ["muss ausgefüllt werden"],
        "items.role_types": ["muss ausgefüllt werden"]
      })
    end

    it "PUT#update updates period invoice template" do
      expect do
        post :update, params: {
          group_id: Group.root.id,
          id: period_invoice_template.id,
          period_invoice_template: {
            name: "Updated Name"
          }
        }
      end.to change { period_invoice_template.reload.name }
      expect(flash[:notice]).to eq "Sammelrechnung <i>Updated Name</i> wurde erfolgreich aktualisiert."
    end

    it "PUT#update updates connected recipient source" do
      start = Date.yesterday
      expect do
        post :update, params: {
          group_id: Group.root.id,
          id: period_invoice_template.id,
          period_invoice_template: {
            start_on: start,
            recipient_group_type: Group::TopLayer.name
          }
        }
      end.to change { period_invoice_template.reload.recipient_group_type }
      entry = period_invoice_template.reload
      expect(entry.recipient_source_type).to eq GroupsFilter.name
      expect(entry.recipient_source.group_type).to eq Group::TopLayer.name
      expect(entry.recipient_source.active_at).to eq start
      expect(entry.recipient_source.parent_id).to eq Group.root.id
    end
  end

  context "feature gate disabled" do
    around do |example|
      original = Settings.groups.period_invoice_templates.enabled
      Settings.groups.period_invoice_templates.enabled = false
      Rails.application.reload_routes!
      example.run
      Settings.groups.period_invoice_templates.enabled = original
      Rails.application.reload_routes!
    end

    it "doesn't allow index when feature toggle is disabled" do
      expect {
        get :index, params: {group_id: Group.root.id}
      }.to raise_error(ActionController::UrlGenerationError)
    end
  end
end
