#  Copyright (c) 2025 BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Contactables::InvoicesController do
  let(:group) { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before { invoices(:invoice).update_columns(state: "issued", issued_at: Time.zone.today) }

  def issued_invoice(**attrs)
    Fabricate(:invoice, state: :issued, issued_at: Time.zone.today,
      invoice_items: [Fabricate.build(:invoice_item)], **attrs)
  end

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

    it "may not show top_leader's invoice although issued by own layer" do
      sign_in(bottom_member)
      expect do
        get :show, params: {group_id: group.id, person_id: top_leader.id, id: invoices(:invoice).id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not download top_leader's invoice as pdf" do
      sign_in(bottom_member)
      expect do
        get :show, params: {group_id: group.id, person_id: top_leader.id, id: invoices(:invoice).id,
                            format: :pdf}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not show group invoice" do
      group_invoice = issued_invoice(group: groups(:bottom_layer_one), recipient: group)
      sign_in(bottom_member)
      expect do
        get :show, params: {group_id: group.id, id: group_invoice.id}
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

        it "may list invoices if filter_by_finance_layer=false" do
          allow(Settings.invoices.filter_by_finance_layer).to receive(:enabled).and_return(false)
          get :index, params: {group_id: group.id, person_id: top_leader.id}
          expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
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
        let!(:group_invoice) { issued_invoice(group: groups(:top_layer), recipient: group) }

        it "may see invoice to own finance layer originating from other layer" do
          get :index, params: {group_id: group.id}
          expect(assigns(:invoices)).to match_array([group_invoice])
        end

        it "may see invoice to group in own finance layer originating from other layer" do
          subgroup = groups(:bottom_group_one_one)
          subgroup_invoice = issued_invoice(group: groups(:top_layer), recipient: subgroup)

          get :index, params: {group_id: subgroup.id}
          expect(assigns(:invoices)).to match_array([subgroup_invoice])
        end

        context "with finance permission only in layer above" do
          let(:acting_user) do
            Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)).person
          end

          it "may index but not see invoice originating from sibling layer" do
            issued_invoice(group: groups(:bottom_layer_two), recipient: group)

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

        it "does not render invoice type checkboxes" do
          get :index, params: {group_id: group.id, person_id: top_leader.id}
          Invoice::TYPE_SCOPES.each do |type|
            expect(dom).not_to have_field(type.to_s)
          end
        end

        it "does not restrict by invoice type when the filter form is submitted" do
          invoices(:invoice).update!(invoice_run: Fabricate(:invoice_run))
          get :index, params: {
            group_id: group.id, person_id: top_leader.id,
            from: "1.1.#{current_year}", to: "31.12.#{current_year}"
          }
          expect(response).to be_successful
          expect(assigns(:invoices)).to match_array invoices(:invoice, :sent)
        end
      end
    end
  end

  context "as recipient" do
    let(:recipient) { Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group)).person }
    let(:manager) { Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group)).person }
    let!(:person_invoice) { issued_invoice(group: groups(:bottom_layer_one), recipient:) }
    let(:person_params) { {group_id: groups(:top_group).id, person_id: recipient.id} }

    let(:recipient_group) { groups(:bottom_layer_one) }
    let(:recipient_group_finance) { people(:bottom_member) }
    let!(:group_invoice) { issued_invoice(group: groups(:top_layer), recipient: recipient_group) }

    before { manager.manageds << recipient }

    shared_examples "reads received invoice" do
      before { sign_in(user) }

      it "sees received invoice" do
        get :index, params: params
        expect(assigns(:invoices)).to include(invoice)
      end

      it "opens received invoice read-only" do
        get :show, params: params.merge(id: invoice.id)
        expect(response).to be_successful
        expect(Ability.new(user)).not_to be_able_to(:update, invoice)
      end

      it "downloads received invoice as pdf" do
        expect do
          get :show, params: params.merge(id: invoice.id, format: :pdf)
        end.to change { Delayed::Job.where("handler LIKE '%Export::InvoicesJob%'").count }.by(1)
        expect(response).to be_redirect
      end
    end

    context "as recipient person" do
      let(:user) { recipient }
      let(:params) { person_params }
      let(:invoice) { person_invoice }

      it_behaves_like "reads received invoice"
    end

    context "as manager of recipient person" do
      let(:user) { manager }
      let(:params) { person_params }
      let(:invoice) { person_invoice }

      it_behaves_like "reads received invoice"
    end

    context "as finance person of recipient group's layer" do
      let(:user) { recipient_group_finance }
      let(:params) { {group_id: recipient_group.id} }
      let(:invoice) { group_invoice }

      it_behaves_like "reads received invoice"
    end

    it "manager of person without roles opens received invoice" do
      recipient.roles.destroy_all
      sign_in(manager)

      get :show, params: person_params.merge(id: person_invoice.id)
      expect(response).to be_successful
    end

    context "with invoice states" do
      before { sign_in(recipient) }

      it "does not show draft invoices" do
        draft = Fabricate(:invoice, group: groups(:bottom_layer_one), recipient:)

        get :index, params: person_params
        expect(assigns(:invoices)).not_to include(draft)
        expect do
          get :show, params: person_params.merge(id: draft.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "shows cancelled invoices which were issued before" do
        person_invoice.update_columns(state: "cancelled")

        get :index, params: person_params.merge(state: "cancelled")
        expect(assigns(:invoices)).to eq [person_invoice]
      end

      it "does not show cancelled invoices which were never issued" do
        person_invoice.update_columns(state: "cancelled", issued_at: nil)

        get :index, params: person_params.merge(state: "cancelled")
        expect(assigns(:invoices)).to be_empty
      end
    end

    it "finance person of recipient group's layer does not see draft invoices" do
      draft = Fabricate(:invoice, group: groups(:top_layer), recipient: recipient_group)
      sign_in(recipient_group_finance)

      get :index, params: {group_id: recipient_group.id}
      expect(assigns(:invoices)).to eq [group_invoice]
      expect(assigns(:invoices)).not_to include(draft)
    end

    it "recipient person may not open invoice received by someone else" do
      sign_in(recipient)

      expect do
        get :show, params: person_params.merge(id: invoices(:invoice).id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finance person of layer above may not open group invoice from sibling layer" do
      sibling_invoice = issued_invoice(group: groups(:bottom_layer_two), recipient: recipient_group)
      sign_in(Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)).person)

      expect do
        get :show, params: {group_id: recipient_group.id, id: sibling_invoice.id}
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "rendering views" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }

      before { sign_in(recipient) }

      it "links to read-only invoice in list" do
        get :index, params: person_params
        expect(dom).to have_link(person_invoice.title,
          href: group_person_received_invoice_path(groups(:top_group), recipient, person_invoice))
      end

      it "renders invoice without write actions" do
        get :show, params: person_params.merge(id: person_invoice.id)
        expect(dom).to have_css("h1", text: person_invoice.title)
        expect(dom).to have_link("Drucken")
        expect(dom).not_to have_link("Bearbeiten")
      end
    end
  end
end
