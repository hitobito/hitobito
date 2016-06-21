# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

require 'spec_helper'

describe TagAbility do

  subject { ability }
  let(:ability) { Ability.new(role.person.reload) }

  context 'person tag' do
    context :layer_and_below_full do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

      it 'may create and show tag in his layer' do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
        tag = create_tag(other)
        is_expected.to be_able_to(:create, tag)
        is_expected.to be_able_to(:show, tag)
      end

      it 'may create and show tag in bottom layer' do
        other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        tag = create_tag(other)
        is_expected.to be_able_to(:create, tag)
        is_expected.to be_able_to(:show, tag)
      end
    end

    context 'layer_and_below_full in bottom layer' do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

      it 'may create and show tag in his layer' do
        other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        tag = create_tag(other)
        is_expected.to be_able_to(:create, tag)
        is_expected.to be_able_to(:show, tag)
      end

      it 'may not create and show tag in top layer' do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
        tag = create_tag(other)
        is_expected.not_to be_able_to(:show, tag)
      end
    end

    context :layer_full do
      let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

      it 'may create and show tag in his layer' do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
        tag = create_tag(other)
        is_expected.to be_able_to(:create, tag)
        is_expected.to be_able_to(:show, tag)
      end

      it 'may not create and show tag in bottom layer' do
        other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        tag = create_tag(other)
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end
    end

    context 'layer_full in bottom layer' do
      let(:role) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)) }

      it 'may create and show tag in his layer' do
        other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        tag = create_tag(other)
        is_expected.to be_able_to(:create, tag)
        is_expected.to be_able_to(:show, tag)
      end

      it 'may not create and show tag in upper layer' do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
        tag = create_tag(other)
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end
    end

    context :group_and_below_read do
      let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

      it 'may not create and show tag in his layer' do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
        tag = create_tag(other)
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end

      it 'may not create and show tag in bottom layer' do
        other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        tag = create_tag(other)
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end
    end
  end

  context 'group tag' do
    context :layer_and_below_full do
      let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

      it 'may not be created and shown' do
        tag = create_tag(groups(:top_group))
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end
    end

    context :layer_full do
      let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

      it 'may not be created and shown' do
        tag = create_tag(groups(:top_group))
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end
    end

    context :group_and_below_read do
      let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

      it 'may not be created and shown' do
        tag = create_tag(groups(:top_group))
        is_expected.not_to be_able_to(:create, tag)
        is_expected.not_to be_able_to(:show, tag)
      end
    end
  end

  def create_tag(taggable)
    Tag.create!(
      name: 'foo',
      taggable: taggable
    )
  end

end
