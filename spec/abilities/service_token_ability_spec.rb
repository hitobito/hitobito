# encoding: utf-8

#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ServiceTokenAbility do

  let(:user)          { role.person }
  let(:group)         { role.group }
  let(:service_token) { Fabricate(:service_token, layer: group) }


  subject { Ability.new(user.reload) }

  context :layer_and_below_full do

    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may create service token in his group' do
      is_expected.to be_able_to(:create, group.service_tokens.new)
    end

    it 'may create service token in his layer' do
      is_expected.to be_able_to(:create, groups(:toppers).service_tokens.new)
    end

    %i(update show edit destroy).each do |action|
      it "may #{action} service_account in his layer" do
        is_expected.to be_able_to(action, service_token)
      end
    end

    %i(update show edit destroy).each do |action|
      it "may not #{action} service_account in layer below" do
        other = Fabricate(:service_token, layer: groups(:bottom_layer_one))
        is_expected.not_to be_able_to(action, other)
      end
    end
  end


  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    it 'may create service token in his group' do
      is_expected.to be_able_to(:create, group.service_tokens.new)
    end

    it 'may create service token in his layer' do
      is_expected.to be_able_to(:create, groups(:toppers).service_tokens.new)
    end

    %i(update show edit destroy).each do |action|
      it "may #{action} service_account in his layer" do
        is_expected.to be_able_to(action, service_token)
      end
    end

    %i(update show edit destroy).each do |action|
      it "may not #{action} service_account in layer below" do
        other = Fabricate(:service_token, layer: groups(:bottom_layer_one))
        is_expected.not_to be_able_to(action, other)
      end
    end

  end
end
