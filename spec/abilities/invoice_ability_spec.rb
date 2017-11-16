
# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceAbility do

  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }
  let(:role) { roles(:bottom_member)}

  context 'in own group' do
    let(:group) { groups(:bottom_layer_one) }

    %w(index manage).each do |action|
      it "may not #{action} invoice list" do
        is_expected.not_to be_able_to(action.to_sym, Invoice)
      end
    end

    %w(create edit show update destroy).each do |action|
      it "may #{action} invoices" do
        is_expected.to be_able_to(action.to_sym, Invoice.new(group: group))
      end
    end
  end

  context 'in other group' do
    let(:group) { groups(:top_layer) }

    %w(index manage).each do |action|
      it "may not #{action} invoice list" do
        is_expected.not_to be_able_to(action.to_sym, Invoice)
      end
    end

    %w(create edit show update destroy).each do |action|
      it "may not #{action} invoices" do
        is_expected.not_to be_able_to(action.to_sym, Invoice.new(group: group))
      end
    end
  end
end
