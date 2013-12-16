# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Role::TypeList do

  it 'contains all roles for top layer' do
    list = Role::TypeList.new(Group::TopLayer)
    list.to_enum.to_a.should == [
      ['Top Layer',
       { 'Top Group' => [Group::TopGroup::Leader, Group::TopGroup::Secretary, Group::TopGroup::Member] }],

      ['Bottom Layer',
       { 'Bottom Layer' => [Group::BottomLayer::Leader, Group::BottomLayer::Member],
         'Bottom Group' => [Group::BottomGroup::Leader, Group::BottomGroup::Member] }],

      ['Global',
       {
        'Global Group' => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member],
        'Global' => [Role::External] }],
    ]
  end

  it 'contains all roles for bottom layer' do
    list = Role::TypeList.new(Group::BottomLayer)
    list.to_enum.to_a.should == [
      ['Bottom Layer',
       { 'Bottom Layer' => [Group::BottomLayer::Leader, Group::BottomLayer::Member],
         'Bottom Group' => [Group::BottomGroup::Leader, Group::BottomGroup::Member] }],

      ['Global',
       {
        'Global Group' => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member],
        'Global' => [Role::External] }],
    ]
  end

  it 'contains all roles for top group' do
    list = Role::TypeList.new(Group::TopGroup)
    list.to_enum.to_a.should == [
      ['Top Group',
       { 'Top Group' => [Group::TopGroup::Leader, Group::TopGroup::Secretary, Group::TopGroup::Member],
         'Global Group' => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member]}],
      ['Global',
       { 'Global' => [Role::External] }],
    ]
  end

  it 'contains all roles for bottom group' do
    list = Role::TypeList.new(Group::BottomGroup)
    list.to_enum.to_a.should == [

      ['Bottom Group',
       {'Bottom Group' => [Group::BottomGroup::Leader, Group::BottomGroup::Member] }],
      ['Global',
       {'Global Group' => [Group::GlobalGroup::Leader, Group::GlobalGroup::Member],
        'Global' => [Role::External] }],
    ]
  end
end
