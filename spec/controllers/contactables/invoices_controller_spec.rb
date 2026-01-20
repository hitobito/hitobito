#  Copyright (c) 2025 BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Contactables::InvoicesController do
  let(:group) { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context "bottom member" do
    it "may not index top_leader's invoices if we have no finance permission in layer" do
      sign_in(bottom_member)
      expect do
        get :index, params: {group_id: group.id, person_id: top_leader.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not index group invoices if we have no finance permission in layer" do
      sign_in(bottom_member)
      expect do
        get :index, params: {group_id: group.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "top leader" do
    before { sign_in(top_leader) }

    it "may index person invoices" do
      get :index, params: {group_id: group.id, person_id: top_leader.id}
      expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
    end

    it "may index group invoices" do
      get :index, params: {group_id: group.id}
      expect(assigns(:invoices)).to match_array(invoices(:group_invoice))
    end

    it "may sort invoices by state" do
      get :index, params: {group_id: group.id, person_id: top_leader.id, sort: :state, sort_dir: :desc}
      expect(assigns(:invoices).first).to eq invoices(:sent)

      get :index, params: {group_id: group.id, person_id: top_leader.id, sort: :state, sort_dir: :asc}
      expect(assigns(:invoices).first).to eq invoices(:invoice)
    end

    it "may sort invoices by last_payment" do
      invoices(:invoice).payments.create!(amount: 1, received_at: 1.day.ago)
      invoices(:sent).payments.create!(amount: 1, received_at: 2.days.ago)

      get :index, params: {group_id: group.id, person_id: top_leader.id, sort: :last_payment_at, sort_dir: :desc}
      expect(assigns(:invoices).first).to eq invoices(:invoice)

      get :index, params: {group_id: group.id, person_id: top_leader.id, sort: :last_payment_at, sort_dir: :asc}
      expect(assigns(:invoices).first).to eq invoices(:sent)
    end

    it "may sort invoices by amount_paid" do
      invoices(:invoice).payments.create!(amount: 4)
      invoices(:sent).payments.create!(amount: 2)

      get :index, params: {group_id: group.id, person_id: top_leader.id, sort: :amount_paid, sort_dir: :desc}
      expect(assigns(:invoices).first).to eq invoices(:invoice)

      get :index, params: {group_id: group.id, person_id: top_leader.id, sort: :amount_paid, sort_dir: :asc}
      expect(assigns(:invoices).first).to eq invoices(:sent)
    end

    describe "rendering views" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }
      let(:current_year) { Time.zone.now.year }

      it "renders filter with default date values" do
        get :index, params: {group_id: group.id, person_id: top_leader.id}
        expect(dom).to have_field("from", with: "1.1.#{current_year}")
        expect(dom).to have_field("to", with: "31.12.#{current_year}")
      end
    end
  end
end
