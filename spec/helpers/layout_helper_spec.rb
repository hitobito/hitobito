# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe LayoutHelper do

  include CrudTestHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  describe '#header_logo_css' do

    it 'should find the logo directly on the visible group' do
      group = Group::BottomLayer.new(name: "Bottom Two")
      group.logo = File.open('spec/fixtures/person/test_picture.jpg')
      group.save

      assign(:group, group)
      expect(helper.header_logo_css).to eql("<style>header.logo a.logo-image { background-image: url(#{asset_path(group.logo)}); }</style>")
    end

    it 'should find the logo on a parent group' do
      parent_group = Group::BottomGroup.new(name: "Group 11", parent: groups(:bottom_layer_one))
      parent_group.logo = File.open('spec/fixtures/person/test_picture.jpg')
      parent_group.save

      group = Group::BottomGroup.new(name: "Group 111")
      group.parent = parent_group
      group.save

      assign(:group, group)
      expect(helper.header_logo_css).to eql("<style>header.logo a.logo-image { background-image: url(#{asset_path(group.parent.logo)}); }</style>")
    end

    it 'should return the correct logo, when multiple are available.' do
      parent_parent_group = Group::BottomGroup.new(name: 'Bottom One', parent: groups(:top_layer))
      parent_parent_group.logo = File.open('spec/fixtures/person/test_picture2.jpg')
      parent_parent_group.save

      parent_group = Group::BottomGroup.new(name: 'Group 11', parent: groups(:bottom_layer_one))
      parent_group.logo = File.open('spec/fixtures/person/test_picture.jpg')
      parent_group.save

      group = Group::BottomGroup.new(name: 'Group 111')
      group.parent = parent_group
      group.save

      assign(:group, group)
      expect(helper.header_logo_css).to eql("<style>header.logo a.logo-image { background-image: url(#{asset_path(group.parent.logo)}); }</style>")
    end

    it 'should return nil when not viewing a group' do
      expect(helper.header_logo_css).to be nil
    end

    it 'should return nil when no logo is found' do
      group = groups(:bottom_group_one_one_one)
      assign(:group, group)
      expect(helper.header_logo_css).to be nil
    end

  end
end
