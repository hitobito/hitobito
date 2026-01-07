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
      expect do
        post :create, params: {
          group_id: Group.root.id,
          period_invoice_template: {
            name: "Test",
            start_on: Time.zone.now
          }
        }
      end.to change { PeriodInvoiceTemplate.count }.by 1
      expect(flash[:notice]).to eq "Sammelrechnung <i>Test</i> wurde erfolgreich erstellt."
    end

    it "PUT#update updates period invoice template" do
      expect do
        post :update,
          params: {group_id: Group.root.id, id: period_invoice_template.id,
                   period_invoice_template: {name: "Updated Name"}}
      end.to change { period_invoice_template.reload.name }
      expect(flash[:notice]).to eq "Sammelrechnung <i>Updated Name</i> wurde erfolgreich aktualisiert."
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
