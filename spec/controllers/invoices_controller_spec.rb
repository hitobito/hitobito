#  Copyright (c) 2017-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoicesController do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }

  before { sign_in(person) }

  context "authorization" do
    it "may index when person has finance permission on layer group" do
      get :index, params: {group_id: group.id}
      expect(response).to be_successful
    end

    it "may edit when person has finance permission on layer group" do
      invoice = Invoice.create!(group: group, title: "test", recipient: person)
      get :edit, params: {group_id: group.id, id: invoice.id}
      expect(response).to be_successful
    end

    it "may not index when person has no finance permission on layer group" do
      expect do
        get :index, params: {group_id: groups(:top_layer).id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has no finance permission on layer group" do
      invoice = Invoice.create!(group: groups(:top_layer), title: "test", recipient: person)
      expect do
        get :edit, params: {group_id: groups(:top_layer).id, id: invoice.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "GET#new" do
    it "GET#new supports creating invoice for without recipient params" do
      get :new, params: {group_id: group.id}
      expect(response).to be_successful
      expect(assigns(:invoice).recipient_id).to be_nil
      expect(assigns(:invoice).recipient_name).to be_nil
    end

    it "GET#new creating invoice for with Person recipient params" do
      get :new, params: {group_id: group.id, invoice: {recipient_type: "Person", recipient_id: person.id}}
      expect(response).to be_successful
      expect(assigns(:invoice).recipient).to be_present
      expect(assigns(:invoice).recipient_name).to be_present
    end

    it "GET#new creating invoice for with Group recipient params" do
      group = groups(:top_layer)
      sign_in(people(:top_leader))
      get :new, params: {group_id: group.id, invoice: {recipient_type: "Group", recipient_id: group.id}}
      expect(response).to be_successful
      expect(assigns(:invoice).recipient).to be_present
      expect(assigns(:invoice).recipient_name).to be_present
    end
  end

  context "GET#index" do
    it "preloads recipients" do
      invoices(:group_invoice).update!(group_id: group.id)

      get :index, params: {group_id: group.id}

      expect_query_count("Invoice Load": 1, "Person Load": 1, "Group Load": 1) do
        assigns(:invoices).to_a
      end

      invoices = assigns(:invoices).to_a

      expect_query_count do
        invoices.each do |invoice|
          invoice.recipient.to_s
        end
      end.to eq 0 # recipients are preloaded, so no additional queries
    end

    it "finds invoices by title" do
      update_issued_at_to_current_year

      get :index, params: {group_id: group.id, q: "Sent"}
      expect(assigns(:invoices)).to have(1).item
    end

    it "finds invoices by sequence_number" do
      get :index, params: {group_id: group.id, q: invoices(:invoice).sequence_number}
      expect(assigns(:invoices)).to have(1).item
    end

    it "finds invoices by recipient people.last_name" do
      update_issued_at_to_current_year

      get :index, params: {group_id: group.id, q: people(:top_leader).last_name}
      expect(assigns(:invoices)).to have(2).item
    end

    it "finds invoices by recipient people.first_name" do
      update_issued_at_to_current_year

      get :index, params: {group_id: group.id, q: people(:top_leader).first_name}
      expect(assigns(:invoices)).to have(2).item
    end

    it "finds invoices by recipient people.email" do
      update_issued_at_to_current_year

      get :index, params: {group_id: group.id, q: people(:top_leader).email}
      expect(assigns(:invoices)).to have(2).item
    end

    it "finds invoices by recipient people.company_name" do
      update_issued_at_to_current_year
      people(:top_leader).update!(company_name: "Hitobito Fanclub")

      get :index, params: {group_id: group.id, q: "hitobito"}
      expect(assigns(:invoices)).to have(2).item
    end

    it "finds nothing by owner.company_name" do
      update_issued_at_to_current_year
      creator = people(:bottom_member)
      creator.update!(company_name: "Greedy Ltd")
      Invoice.update_all(creator_id: creator.id)

      get :index, params: {group_id: group.id, q: creator.company_name}
      expect(assigns(:invoices)).to be_empty
    end

    it "finds nothing for dummy" do
      get :index, params: {group_id: group.id, q: "dummy"}
      expect(assigns(:invoices)).to be_empty
    end

    context "group invoices" do
      let(:group) { groups(:top_layer) }
      let(:person) { people(:top_leader) }

      it "GET#index finds invoices by recipient groups.name" do
        update_issued_at_to_current_year
        get :index, params: {group_id: group.id, q: groups(:top_group).name}
        expect(assigns(:invoices)).to have(1).item
      end

      it "GET#index finds invoices by recipient groups.email" do
        groups(:top_group).update!(email: "top_group@example.com")
        update_issued_at_to_current_year
        get :index, params: {group_id: group.id, q: groups(:top_group).email}
        expect(assigns(:invoices)).to have(1).item
      end
    end

    it "filters invoices by state" do
      get :index, params: {group_id: group.id, state: :draft}
      expect(assigns(:invoices)).to have(1).item
    end

    it "filters invoices by daterange" do
      invoice.update(issued_at: Time.zone.today)
      get :index, params: {group_id: group.id,
                           from: 1.year.ago.beginning_of_year,
                           to: 1.year.ago.end_of_year}
      expect(assigns(:invoices)).not_to include invoice
    end

    it "filters invoices by year with default set to current year" do
      invoice.update(issued_at: Time.zone.today)
      travel_to(1.year.ago) do
        get :index, params: {group_id: group.id}
      end
      expect(assigns(:invoices)).not_to include invoice
    end

    it "filters invoices by due_since" do
      invoice.update(due_at: 2.weeks.ago)
      get :index, params: {group_id: group.id, due_since: :one_week}
      expect(assigns(:invoices)).to have(1).item
    end

    it "ignores page param when passing in ids" do
      update_issued_at_to_current_year
      get :index, params: {group_id: group.id, ids: Invoice.pluck(:id).join(","), page: 2}
      expect(assigns(:invoices)).to have(2).items
    end

    it "exports pdf in background ordered by sequence number asc" do
      update_issued_at_to_current_year

      expected_ids = [invoice.id, invoices(:sent).id]
      expect(Export::InvoicesJob).to receive(:new).with(anything, anything, expected_ids, anything).and_call_original

      expect do
        get :index, params: {
          group_id: group.id,
          sort: :sequence_number,
          sort_dir: :asc
        }, format: :pdf
      end.to change { Delayed::Job.count }.by(1)
    end

    it "exports pdf in background ordered by sequence number desc" do
      update_issued_at_to_current_year

      expected_ids = [invoices(:sent).id, invoice.id]
      expect(Export::InvoicesJob).to receive(:new).with(anything, anything, expected_ids, anything).and_call_original

      expect do
        get :index, params: {
          group_id: group.id,
          sort: :sequence_number,
          sort_dir: :desc
        }, format: :pdf
      end.to change { Delayed::Job.count }.by(1)
    end

    context "invoice run" do
      let(:sent) { invoices(:sent) }
      let(:letter) { messages(:with_invoice) }
      let(:invoice_run) { messages(:with_invoice).create_invoice_run(title: "test", group_id: group.id) }
      let(:top_leader) { people(:top_leader) }

      before do
        update_issued_at_to_current_year
        sent.update(invoice_run: invoice_run)
      end

      it "does not include invoice when viewing group invoices" do
        get :index, params: {group_id: group.id}
        expect(assigns(:invoices)).not_to include sent
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
    end

    it "exports labels pdf" do
      get :index, params: {group_id: group.id, label_format_id: label_formats(:standard).id}, format: :pdf
      expect(response.media_type).to eq("application/pdf")
    end

    it "exports pdf" do
      update_issued_at_to_current_year
      get :index, params: {group_id: group.id}, format: :csv
      expect(response.header["Content-Disposition"]).to match(/rechnungen.csv/)
      expect(response.media_type).to eq("text/csv")
    end

    it "renders json" do
      update_issued_at_to_current_year
      get :index, params: {group_id: group.id}, format: :json
      json = JSON.parse(response.body).deep_symbolize_keys
      expect(json[:current_page]).to eq 1
      expect(json[:total_pages]).to eq 1
      expect(json[:next_page_link]).to be_nil
      expect(json[:prev_page_link]).to be_nil
      expect(json[:invoices]).to have(2).items

      expect(json[:invoices].first[:links][:invoice_items]).to have(2).items
      expect(json[:invoices].last[:links][:invoice_items]).to have(1).items

      expect(json[:linked][:groups]).to have(1).item
      expect(json[:linked][:groups].first[:id].to_i).to eq groups(:bottom_layer_one).id

      expect(json[:linked][:invoice_items]).to have(3).items

      expect(json[:links][:"invoices.creator"][:href]).to eq "http://test.host/de/people/{invoices.creator}.json"
      expect(json[:links][:"invoices.recipient"][:href]).to eq "http://test.host/de/people/{invoices.recipient}.json"
    end

    context "rendering view" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }
      let(:current_year) { Time.zone.now.year }

      it "renders invoice with title" do
        invoice.update(title: "Testrechnung")
        get :index, params: {group_id: group.id}
        expect(dom).to have_link "Testrechnung", href: group_invoice_path(group_id: group.id, id: invoice.id)
      end

      it "renders filter with default date values" do
        get :index, params: {group_id: group.id}
        expect(dom).to have_field("from", with: "1.1.#{current_year}")
        expect(dom).to have_field("to", with: "31.12.#{current_year}")
      end

      it "renders filter with date values from invoice run" do
        invoice_run = InvoiceRun.create!(title: "test", group:, created_at: Time.zone.local(2025, 10, 12))
        invoice.update(invoice_run:)

        get :index, params: {group_id: group.id, invoice_run_id: invoice_run.id}
        expect(dom).to have_field("from", with: "1.1.2025")
        expect(dom).to have_field("to", with: "31.12.2025")
      end
    end
  end

  context "GET#show" do
    it "GET#show assigns payment if invoice has been sent" do
      invoice.update(state: :sent)
      get :show, params: {group_id: group.id, id: invoice.id}
      expect(assigns(:payment)).to be_present
      expect(assigns(:payment_valid)).to eq true
      expect(assigns(:payment).amount.to_f).to eq 5.35
    end

    it "GET#show assigns payment with amount_open" do
      invoice.update(state: :sent)
      invoice.payments.create!(amount: 0.5)
      get :show, params: {group_id: group.id, id: invoice.id}
      expect(assigns(:payment)).to be_present
      expect(assigns(:payment_valid)).to eq true
      expect(assigns(:payment).amount.to_f).to eq 4.85
    end

    it "GET#show assigns payment with flash parameters" do
      invoice.update(state: :sent)
      allow(subject).to receive(:flash).and_return(payment: {})
      get :show, params: {group_id: group.id, id: invoice.id}
      expect(assigns(:payment)).to be_present
      expect(assigns(:payment_valid)).to eq false
    end

    it "exports pdf" do
      expect do
        get :show, params: {group_id: group.id, id: invoice.id}, format: :pdf
      end.to change { Delayed::Job.count }.by(1)
    end

    it "exports pdf without payment_slip when payment_slip: false" do
      expect(Export::InvoicesJob).to receive(:new).with(:pdf, person.id, [invoice.id],
        hash_including(payment_slip: false)).and_call_original
      get :show, params: {group_id: group.id, id: invoice.id, payment_slip: false}, format: :pdf
    end

    it "exports pdf without articles when articles: false" do
      expect(Export::InvoicesJob).to receive(:new).with(:pdf, person.id, [invoice.id],
        hash_including(articles: false)).and_call_original
      get :show, params: {group_id: group.id, id: invoice.id, articles: false}, format: :pdf
    end

    it "exports pdf without reminders when reminders: false" do
      expect(Export::InvoicesJob).to receive(:new).with(:pdf, person.id, [invoice.id],
        hash_including(reminders: false)).and_call_original
      get :show, params: {group_id: group.id, id: invoice.id, reminders: false}, format: :pdf
    end

    it "exports csv" do
      get :show, params: {group_id: group.id, id: invoice.id}, format: :csv

      expect(response.header["Content-Disposition"]).to match(/Rechnung-#{invoice.sequence_number}.csv/)
      expect(response.media_type).to eq("text/csv")
    end

    it "renders json" do
      get :show, params: {group_id: group.id, id: invoice.id}, format: :json
      json = JSON.parse(response.body).deep_symbolize_keys
      expect(json[:invoices]).to have(1).items
      expect(json[:invoices].first[:total]).to eq "5.35"
      expect(json[:invoices].first[:links][:invoice_items]).to have(2).items

      expect(json[:linked][:groups]).to have(1).item
      expect(json[:linked][:groups].first[:id].to_i).to eq groups(:bottom_layer_one).id

      expect(json[:linked][:invoice_items]).to have(2).items

      expect(json[:links][:"invoices.creator"][:href]).to eq "http://test.host/de/people/{invoices.creator}.json"
      expect(json[:links][:"invoices.recipient"][:href]).to eq "http://test.host/de/people/{invoices.recipient}.json"
    end
  end

  context "DELETE#destroy" do
    it "moves invoice to cancelled state" do
      expect do
        delete :destroy, params: {group_id: group.id, id: invoice.id}
      end.not_to change { group.issued_invoices.count }
      expect(invoice.reload.state).to eq "cancelled"
      expect(response).to redirect_to group_invoices_path(group, returning: true)
      expect(flash[:notice]).to eq "Rechnung wurde storniert."
    end

    it "updates and redirects to invoice_run" do
      run = InvoiceRun.create(title: "List", group: group, invoices: [invoice, invoices(:sent)])

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

  context "POST#create" do
    it "POST#create sets creator_id to current_user" do
      expect do
        post :create, params: {group_id: group.id, invoice: {
          title: "current_user",
          recipient_type: "Person",
          recipient_id: person.id
        }}
      end.to change { Invoice.count }.by(1)

      expect(Invoice.find_by(title: "current_user").creator).to eq(person)
    end

    it "POST#create allows to manually adjust the recipient address" do
      expect do
        post :create,
          params: {group_id: group.id,
                   invoice: {
                     title: "current_user",
                     recipient_type: "Person",
                     recipient_id: person.id,
                     recipient_name: "Tim Testermann",
                     recipient_street: "Alphastrasse", recipient_housenumber: "1", recipient_zip_code: "8000",
                     recipient_town: "Zürich"
                   }}
      end.to change { Invoice.count }.by(1)

      expect(Invoice.find_by(title: "current_user").recipient_address_values).to eq [
        "Tim Testermann", "Alphastrasse 1", "8000 Zürich"
      ]
    end

    it "POST#create allows to manually adjust the recipient email" do
      expect do
        post :create,
          params: {group_id: group.id,
                   invoice: {
                     title: "current_user",
                     recipient_type: "Person",
                     recipient_id: person.id,
                     recipient_email: "test@unit.com"
                   }}
      end.to change { Invoice.count }.by(1)

      expect(Invoice.find_by(title: "current_user").recipient_email).to eq("test@unit.com")
    end

    it "POST#create accepts nested attributes for invoice_items" do
      expect do
        post :create, params: {
          group_id: group.id,
          invoice: {
            title: "current_user",
            recipient_type: "Person",
            recipient_id: person.id,
            invoice_items_attributes: {
              "1": {
                name: "pen",
                description: "simple pen",
                cost_center: "board",
                account: "advertisment",
                vat_rate: 0.0,
                unit_cost: 22.0,
                count: 1,
                _destroy: false
              }

            }
          }
        }
      end.to change { Invoice.count }.by(1)
      expect(assigns(:invoice).invoice_items).to have(1).entry
      expect(assigns(:invoice).invoice_items.first.cost_center).to eq "board"
      expect(assigns(:invoice).invoice_items.first.account).to eq "advertisment"
    end
  end

  def update_issued_at_to_current_year
    sent = invoices(:sent)
    if sent.issued_at.year != Time.zone.today.year
      sent.update(issued_at: Time.zone.today.beginning_of_year)
    end
  end
end
