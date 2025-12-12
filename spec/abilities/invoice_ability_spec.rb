#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceAbility do
  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  [
    %w[bottom_member bottom_layer_one top_layer],
    %w[top_leader top_layer bottom_layer_one]
  ].each do |role, own_group, other_group|
    context role do
      let(:role) { roles(role) }
      let(:invoice) { Invoice.new(group: group) }
      let(:article) { InvoiceArticle.new(group: group) }
      let(:reminder) { invoice.payment_reminders.build }
      let(:payment) { invoice.payments.build }

      it "may index" do
        is_expected.to be_able_to(:index, Invoice)
      end

      it "may not index InvoiceItem" do
        is_expected.not_to be_able_to(:index, InvoiceItem)
      end

      it "may not manage" do
        is_expected.not_to be_able_to(:manage, Invoice)
        is_expected.not_to be_able_to(:manage, InvoiceItem)
      end

      context "in own group" do
        let(:group) { groups(own_group) }

        %w[create edit show update destroy].each do |action|
          it "may #{action} invoices in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, invoice)
          end
        end

        %w[create edit show update destroy].each do |action|
          it "may #{action} invoice_item in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, invoice.invoice_items.build)
          end
        end

        %w[create edit show update destroy].each do |action|
          it "may #{action} articles in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, article)
          end
        end

        [:reminder, :payment].each do |obj|
          it "may create #{obj} in #{own_group}" do
            is_expected.to be_able_to(:create, send(obj))
          end
        end

        %w[edit show update].each do |action|
          it "may #{action} invoice_config in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, group.invoice_config)
          end
        end
      end

      context "in other group" do
        let(:group) { groups(other_group) }

        %w[create edit show update destroy].each do |action|
          it "may not #{action} invoices in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, invoice)
          end
        end

        %w[create edit show update destroy].each do |action|
          it "may not #{action} invoices in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, invoice.invoice_items.build)
          end
        end

        %w[create edit show update destroy].each do |action|
          it "may not #{action} articles in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, article)
          end
        end

        [:reminder, :payment].each do |obj|
          it "may not create #{obj} in #{own_group}" do
            is_expected.not_to be_able_to(:create, send(obj))
          end
        end

        %w[edit show update destroy].each do |action|
          it "may not #{action} invoice_config in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, group.invoice_config)
          end
        end
      end
    end
  end

  context "InvoiceRun" do
    def invoice_run(group, abo_group)
      InvoiceRun.new(group: groups(group), receiver: groups(abo_group).mailing_lists.build)
    end

    def ability(role)
      Ability.new(roles(role).person)
    end

    it "top_leader may work only with abos in his layer" do
      expect(ability(:top_leader)).to be_able_to(:create, invoice_run(:top_layer, :top_layer))
      expect(ability(:top_leader)).to be_able_to(:create, invoice_run(:top_layer, :top_group))
      expect(ability(:top_leader)).not_to be_able_to(:create,
        invoice_run(:top_layer, :bottom_layer_one))
    end

    it "bottom_member may work only with abos in his layer" do
      expect(ability(:bottom_member)).to be_able_to(:create,
        invoice_run(:bottom_layer_one, :bottom_layer_one))
      expect(ability(:bottom_member)).not_to be_able_to(:create,
        invoice_run(:bottom_layer_one, :top_group))
      expect(ability(:bottom_member)).not_to be_able_to(:create,
        invoice_run(:bottom_layer_one, :top_layer))
    end
  end

  context "with layer_and_below_finance permission" do
    let(:role) { roles(:top_leader) }

    Group.layers.each do |layer|
      before do
        layer.send(:create_invoice_config)
        layer.invoice_config.update(sequence_number: "1")

        allow_any_instance_of(Group::TopGroup::Leader).to receive(:permissions)
          .and_return([:layer_and_below_finance])
      end

      context "on invoice" do
        let(:invoice) {
          Fabricate(:invoice, group: layer, recipient_email: "member@example.hitobito.com")
        }

        [:show, :create, :edit, :update, :destroy].each do |action|
          it "can #{action} in #{layer.name}" do
            is_expected.to be_able_to(action, invoice)
          end
        end
      end

      context "on invoice run" do
        let(:invoice_run) { InvoiceRun.create(group: layer, receiver: layer) }

        [:update, :destroy, :create, :index_invoices].each do |action|
          it "can #{action} in #{layer.name}" do
            is_expected.to be_able_to(action, invoice_run)
          end
        end
      end

      context "on invoice article" do
        let(:invoice_article) { InvoiceArticle.create(group: layer, name: "Membership", number: 1) }

        [:show, :new, :create, :edit, :update, :destroy].each do |action|
          it "can #{action} in #{layer.name}" do
            is_expected.to be_able_to(action, invoice_article)
          end
        end
      end

      context "on invoice config" do
        let(:invoice_config) { layer.invoice_config }

        [:show, :edit, :update].each do |action|
          it "can #{action} in #{layer.name}" do
            is_expected.to be_able_to(action, invoice_config)
          end
        end
      end

      context "on payment" do
        let(:invoice) {
          Fabricate(:invoice, group: layer, recipient_email: "member@example.hitobito.com")
        }
        let(:payment) { Payment.new(invoice: invoice, amount: 10) }

        [:create].each do |action|
          it "can #{action} in #{layer.name}" do
            is_expected.to be_able_to(action, payment)
          end
        end
      end

      context "on payment reminder" do
        let(:invoice) {
          Fabricate(:invoice, group: layer,
            recipient_email: "member@example.hitobito.com",
            state: :issued,
            invoice_items: [
              InvoiceItem.new(
                name: "Membership",
                count: 1,
                unit_cost: 100
              )
            ])
        }
        let(:payment_reminder) { PaymentReminder.create(invoice: invoice, level: 1) }

        [:create].each do |action|
          it "can #{action} in #{layer.name}" do
            is_expected.to be_able_to(action, payment_reminder)
          end
        end
      end
    end
  end
end
