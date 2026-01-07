#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplatesController do
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }

  def featureGateActive(condition)
    Settings.groups.period_invoice_templates.enabled = condition
    Rails.application.reload_routes!
  end

  before do
    sign_in(people(:top_leader))
    period_invoice_template.save!
  end

  it "doesn't allow sow when feature toggle is disabled" do
    featureGateActive(false)
    expect {
      get :index, params: {group_id: Group.root.id}
    }.to raise_error(ActionController::UrlGenerationError)
  end

  it "GET#index does list period invoice templates" do
    featureGateActive(true)
    get :index, params: {group_id: Group.root.id}
    expect(assigns(:period_invoice_templates)).to include(period_invoice_template)
  end

  it "POST#create creates a new period invoice template" do
    featureGateActive(true)
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
    featureGateActive(true)
    expect do
      post :update,
        params: {group_id: Group.root.id, id: period_invoice_template.id,
                 period_invoice_template: {name: "Updated Name"}}
    end.to change { period_invoice_template.reload.name }
    expect(flash[:notice]).to eq "Sammelrechnung <i>Updated Name</i> wurde erfolgreich aktualisiert."
  end
end
