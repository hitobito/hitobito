#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplates::InvoiceRunsController do
  let(:group) { groups(:top_layer) }
  let(:period_invoice_template) { Fabricate(:period_invoice_template, group:) }

  around do |example|
    original = Settings.groups.period_invoice_templates.enabled
    Settings.groups.period_invoice_templates.enabled = true
    Rails.application.reload_routes!
    example.run
    Settings.groups.period_invoice_templates.enabled = original
    Rails.application.reload_routes!
  end

  before do
    sign_in(people(:top_leader))
    3.times do
      Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two))
      Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two))
    end
    groups(:bottom_layer_two).update!(street: "Greatstreet", zip_code: 8000, town: "Bern")
  end

  it "GET#index lists invoice runs" do
    run = InvoiceRun.create!(group:, title: "title", recipients_processed: 20,
      recipients_total: 20, recipient_source: GroupsFilter.new, period_invoice_template:)
    get :index, params: {group_id: group.id,
                         period_invoice_template_id: period_invoice_template.id}
    expect(assigns(:invoice_runs)).to match_array([run])
  end

  it "GET#new assigns attributes and renders crud/new template" do
    get :new, params: {group_id: group.id, period_invoice_template_id: period_invoice_template.id}
    expect(response).to render_template("crud/new")
    expect(assigns(:invoice_run).group).to eq group
    expect(assigns(:invoice_run).invoice.invoice_items.length).to eq 1
    expect(assigns(:invoice_run).invoice.invoice_items[0].type).to eq Invoice::RoleCountItem.name
    expect(assigns(:invoice_run).invoice.invoice_items[0].dynamic_cost_parameters).to eq({
      unit_cost: "5.00",
      role_types: [Group::BottomLayer::LocalGuide.name],
      period_start_on: Time.zone.yesterday,
      period_end_on: Time.zone.today.next_year
    })
    expect(assigns(:invoice_run).invoice.invoice_items[0].count).to eq 9
  end

  it "POST#create creates a new invoice run" do
    expect do
      post :create, params: {
        group_id: Group.root.id,
        period_invoice_template_id: period_invoice_template.id,
        invoice_run: {
          invoice: {
            title: "Test run",
            description: "Description",
            payment_information: "Payment info",
            payment_purpose: "Purpose",
            issued_at: Time.zone.today
          }
        }
      }
    end.to change { InvoiceRun.count }.by(1).and change { Invoice.count }.by(2)
    expect(flash[:notice]).to eq "Rechnung <i>Test run</i> wurde für 2 Empfänger erstellt."
  end
end
