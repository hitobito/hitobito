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
    let(:acting_user) { people(:top_leader) }

    before { sign_in(acting_user) }

    context "without finance permission in layer" do
      context "for oneself" do
        it "may list invoices" do
          get :index, params: {group_id: group.id, person_id: top_leader.id}
          expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
        end
      end

      context "for managed" do
        let(:acting_user) do
          Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)).person.tap do |u|
            u.manageds << top_leader
            u.save!
          end
        end

        it "may list invoices" do
          get :index, params: {group_id: group.id, person_id: top_leader.id}
          expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
        end
      end

      context "for other person" do
        let(:acting_user) do
          Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)).person
        end

        it "may view page but see no invoices" do
          get :index, params: {group_id: group.id, person_id: top_leader.id}
          expect(assigns(:invoices)).to be_empty
        end
      end
    end

    context "with finance permission in layer in which invoices have been created" do
      let(:acting_user) do
        Fabricate(Group::BottomLayer::Member.sti_name, group: groups(:bottom_layer_one)).person
      end
      let(:group) { groups(:bottom_layer_one) }

      before do
        Fabricate(Group::BottomLayer::Member.sti_name, group:, person: top_leader)
      end

      it "may index person invoices sent from own layer" do
        get :index, params: {group_id: group.id, person_id: top_leader.id}
        expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
      end

      it "may index person invoices" do
        get :index, params: {group_id: group.id, person_id: top_leader.id}
        expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
      end

      context "group invoices" do
        let!(:group_invoice) { Fabricate(:invoice, group: groups(:top_layer), recipient: group) }

        it "may index but not see invoice originating from other layer" do
          get :index, params: {group_id: group.id}
          expect(assigns(:invoices)).to be_empty
        end

        context "with finance permission in originating layer" do
          before do
            Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group), person: acting_user)
          end

          it "may index" do
            get :index, params: {group_id: group.id}
            expect(assigns(:invoices)).to match_array([group_invoice])
          end
        end
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
end
