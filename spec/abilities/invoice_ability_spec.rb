
# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceAbility do

  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  [ %w(bottom_member finance),
    %w(bottom_leader admin)].each do |role, permission|

    before do
      allow(Group::BottomLayer::Leader).to receive(:permissions).and_return([:admin])
    end

    context permission do
      let(:role) { send(role)}
      let(:invoice) { Invoice.new(group: group) }
      let(:own_group) { groups(:bottom_layer_one) }
      let(:other_group) { groups(:top_layer) }

      it 'may index' do
        is_expected.to be_able_to(:index, Invoice)
      end

      it 'may not manage' do
        is_expected.not_to be_able_to(:manage, Invoice)
      end

      context 'in own group' do
        let(:group) { groups(:bottom_layer_one) }


        %w(create edit show update destroy).each do |action|
          it "may #{action} invoices" do
            is_expected.to be_able_to(action.to_sym, invoice)
          end
        end
      end

      context 'in other group' do
        let(:group) { groups(:top_layer) }

        %w(create edit show update destroy).each do |action|
          it "may not #{action} invoices" do
            is_expected.not_to be_able_to(action.to_sym, invoice)
          end
        end
      end
    end
  end

  context :top_leader do
    let(:role) { roles(:top_leader) }

    it 'may not index' do
      is_expected.not_to be_able_to(:index, Invoice)
    end

  end

  def bottom_member
    roles(:bottom_member)
  end

  def bottom_leader
    @bottom_leader ||= Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
  end

end
