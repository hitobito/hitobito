
# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceAbility do

  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  [
    %w(bottom_member bottom_layer_one top_layer),
    %w(top_leader top_layer bottom_layer_one)
  ].each do |role, own_group, other_group|
    context role do
      let(:role)     { roles(role)}
      let(:invoice)  { Invoice.new(group: group) }
      let(:article)  { InvoiceArticle.new(group: group) }
      let(:reminder) { invoice.payment_reminders.build }
      let(:payment)  { invoice.payments.build }

      it 'may not index' do
        is_expected.not_to be_able_to(:index, Invoice)
      end

      it 'may not manage' do
        is_expected.not_to be_able_to(:manage, Invoice)
      end

      context 'in own group' do
        let(:group) { groups(own_group) }

        %w(create edit show update destroy).each do |action|
          it "may #{action} invoices in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, invoice)
          end
        end

        %w(create edit show update destroy).each do |action|
          it "may #{action} articles in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, article)
          end
        end

        [:reminder, :payment].each do |obj|
          it "may create #{obj} in #{own_group}" do
            is_expected.to be_able_to(:create, send(obj))
          end
        end

        %w(edit show update).each do |action|
          it "may #{action} invoice_config in #{own_group}" do
            is_expected.to be_able_to(action.to_sym, group.invoice_config)
          end
        end
      end

      context 'in other group' do
        let(:group) { groups(other_group) }

        %w(create edit show update destroy).each do |action|
          it "may not #{action} invoices in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, invoice)
          end
        end

        %w(create edit show update destroy).each do |action|
          it "may not #{action} articles in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, article)
          end
        end

        [:reminder, :payment].each do |obj|
          it "may not create #{obj} in #{own_group}" do
            is_expected.not_to be_able_to(:create, send(obj))
          end
        end

        %w(edit show update destroy).each do |action|
          it "may not #{action} invoice_config in #{other_group}" do
            is_expected.not_to be_able_to(action.to_sym, group.invoice_config)
          end
        end
      end
    end
  end

  context 'InvoiceList' do

    def invoice_list(group, abo_group)
      InvoiceList.new(group: groups(group), receiver: groups(abo_group).mailing_lists.build)
    end

    def ability(role)
      Ability.new(roles(role).person)
    end

    it 'top_leader may work only with abos in his layer' do
      expect(ability(:top_leader)).to be_able_to(:create, invoice_list(:top_layer, :top_layer))
      expect(ability(:top_leader)).to be_able_to(:create, invoice_list(:top_layer, :top_group))
      expect(ability(:top_leader)).not_to be_able_to(:create, invoice_list(:top_layer, :bottom_layer_one))
    end

    it 'bottom_member may work only with abos in his layer' do
      expect(ability(:bottom_member)).to be_able_to(:create, invoice_list(:bottom_layer_one, :bottom_layer_one))
      expect(ability(:bottom_member)).not_to be_able_to(:create, invoice_list(:bottom_layer_one, :top_group))
      expect(ability(:bottom_member)).not_to be_able_to(:create, invoice_list(:bottom_layer_one, :top_layer))
    end
  end

end
