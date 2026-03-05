#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::InvoicesController do
  let(:group) { groups(:bottom_layer_one) }
  let(:recipient_source) { PeopleFilter.new(group:, range: "deep", filter_chain: {}) }
  let(:invoice_run) { InvoiceRun.create!(title: "Run", group:, recipient_source:) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }

  before do
    sign_in(person)
    invoice.update!(invoice_run: invoice_run)
  end

  context "authorization" do
    it "may index when person has finance permission on layer group" do
      get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}
      expect(response).to be_successful
    end

    it "may edit when person has finance permission on layer group" do
      invoice = Invoice.create!(group: group, title: "test", recipient: person, invoice_run:)
      get :edit, params: {group_id: group.id, invoice_run_id: invoice_run.id, id: invoice.id}
      expect(response).to be_successful
    end

    it "may not index when person has no finance permission on layer group" do
      top_group = groups(:top_layer)
      invoice_run.update!(group_id: top_group.id)
      expect do
        get :index, params: {group_id: top_group.id, invoice_run_id: invoice_run.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has no finance permission on layer group" do
      top_group = groups(:top_layer)
      invoice_run.update!(group_id: top_group.id)
      invoice = Invoice.create!(group: top_group, title: "test", recipient: person, invoice_run:)
      expect do
        get :edit, params: {group_id: groups(:top_layer).id, invoice_run_id: invoice_run.id, id: invoice.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "GET#index" do
    context "invoices" do
      let(:sent) { invoices(:sent) }
      let(:letter) { messages(:with_invoice) }
      let(:invoice_run) {
        messages(:with_invoice).create_invoice_run(title: "test", group_id: group.id,
          recipient_source: PeopleFilter.new)
      }
      let(:top_leader) { people(:top_leader) }

      before do
        update_issued_at_to_current_year
        sent.update(invoice_run: invoice_run)
      end

      it "does include invoice when viewing invoice run invoices" do
        get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}
        expect(assigns(:invoices)).to include sent
      end

      it "does include invoice when viewing invoice run invoices in next year" do
        travel_to(1.year.from_now) do
          get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}
          expect(assigns(:invoices)).to include sent
        end
      end

      it "does render pdf using invoice renderer" do
        expect do
          get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}, format: :pdf
        end.to change { Delayed::Job.count }.by(1)
      end

      it "does render pdf Letter renderer renderer" do
        top_leader.update(
          street: "Greatstreet",
          housenumber: "345",
          zip_code: 3456,
          town: "Greattown",
          country: "CH"
        )

        invoice_run.update(message: letter)

        expect(Export::MessageJob).to receive(:new)
          .with(:pdf, person.id, letter.id, Hash)
          .and_call_original
        expect do
          get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}, format: :pdf
        end.to change { Delayed::Job.count }.by(1)
      end

      context "rendering view" do
        render_views
        let(:dom) { Capybara::Node::Simple.new(response.body) }
        let(:current_year) { Time.zone.now.year }

        it "renders filter with date values from invoice run" do
          invoice_run = InvoiceRun.create!(title: "test", group:, created_at: Time.zone.local(2025, 10, 12),
            recipient_source: PeopleFilter.new)
          invoice.update(invoice_run:)

          get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}
          expect(dom).to have_field("from", with: "1.1.2025")
          expect(dom).to have_field("to", with: "31.12.2025")
        end
      end
    end

    context "invalid_recipient_ids" do
      it "displays flash message about invalid recipient ids" do
        invoice_run.update(invalid_recipient_ids: [person.id])

        get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}

        expect(flash[:warning]).to eq(
          "Für einen Empfänger konnte keine gültige Rechnung erzeugt werden.<br/>Bottom Member"
        )
      end

      it "does not display flash message if no invalid recipient ids" do
        invoice_run.update(invalid_recipient_ids: [])

        get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}

        expect(flash[:warning]).to be_nil
      end

      it "does not expose people which aren't accessible by the current user" do
        invisible_person = Fabricate(:person)
        invoice_run.update(invalid_recipient_ids: [person.id, invisible_person.id])

        get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}

        expect(flash[:warning]).to eq(
          "Für 2 Empfänger konnte keine gültige Rechnung erzeugt werden.<br/>Bottom Member"
        )
      end

      it "works with group recipients" do
        group_recipients = GroupsFilter.create!(parent: groups(:top_layer), group_type: "Group::BottomLayer",
          active_at: Time.zone.today)
        invoice_run.update(recipient_source: group_recipients)
        invoice_run.update(invalid_recipient_ids: [groups(:bottom_layer_one).id])

        get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}

        expect(flash[:warning]).to eq(
          "Für einen Empfänger konnte keine gültige Rechnung erzeugt werden.<br/>Bottom One"
        )
      end
    end
  end

  context "DELETE#destroy" do
    it "updates and redirects to invoice_run" do
      run = InvoiceRun.create(title: "List", group: group, invoices: [invoice, invoices(:sent)],
        recipient_source: PeopleFilter.new)

      run.update_total
      expect(run.recipients_total).to eq(2)
      expect(run.amount_total.to_f).to eq(5.85)

      invoice.reload

      expect do
        delete :destroy, params: {group_id: group.id, invoice_run_id: run.id, id: invoice.id}
      end.not_to change { group.issued_invoices.count }
      expect(response).to redirect_to(group_invoice_run_invoices_path(group, run, returning: true))
      expect(invoice.reload.state).to eq "cancelled"

      run.reload

      expect(run.recipients_total).to eq(1)
      expect(run.amount_total).to eq(0.5)
    end
  end

  def update_issued_at_to_current_year
    sent = invoices(:sent)
    if sent.issued_at.year != Time.zone.today.year
      sent.update(issued_at: Time.zone.today.beginning_of_year)
    end
  end
end
