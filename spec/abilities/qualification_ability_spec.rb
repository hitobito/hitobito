# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe QualificationAbility do

  let(:user) { role.person }
  let(:group) { role.group }

  subject { Ability.new(user.reload) }


  let(:qualification) { Fabricate(:qualification, person: person) }

  describe 'top leader' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context 'on bottom member' do
      let(:person) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }

      it 'can create and destroy' do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end

    context 'on top member' do
      let(:person) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person }

      it 'can create and destroy' do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end
  end

  describe 'local leader' do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    context 'on bottom member' do
      let(:person) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }

      it 'cannot create and destroy' do
        should_not be_able_to(:create, qualification)
        should_not be_able_to(:destroy, qualification)
      end
    end

    context 'on top member' do
      let(:person) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person }

      it 'can create and destroy' do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end
  end

  describe 'bottom leader' do
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

    context 'on top member' do
      let(:person) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person }

      it 'cannot create and destroy' do
        should_not be_able_to(:create, qualification)
        should_not be_able_to(:destroy, qualification)
      end
    end

    context 'on bottom member' do
      let(:person) { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person }

      it 'create and destroy' do
        should be_able_to(:create, qualification)
        should be_able_to(:destroy, qualification)
      end
    end
  end


end
