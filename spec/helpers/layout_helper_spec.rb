# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe LayoutHelper do

  describe '#header_logo_css' do

    let(:group) { groups(:bottom_group_one_one_one) }
    let(:parent) { groups(:bottom_group_one_one) }
    let(:grandparent) { groups(:bottom_layer_one) }

    before { assign(:group, group) }

    it 'should find the logo directly on the visible group' do
      group.update_attributes(logo: File.open('spec/fixtures/person/test_picture.jpg'))

      expect(helper.header_logo_css).to eql("<style>header.logo a.logo-image { background-image: url(#{asset_path(group.logo)}); }</style>")
    end

    it 'should find the logo on a parent group' do
      parent.update_attributes(logo: File.open('spec/fixtures/person/test_picture2.jpg'))
      expect(helper.header_logo_css).to eql("<style>header.logo a.logo-image { background-image: url(#{asset_path(parent.logo)}); }</style>")
    end

    it 'should return the correct logo, when multiple are available.' do
      grandparent.update_attributes(logo: File.open('spec/fixtures/person/test_picture2.jpg'))
      parent.update_attributes(logo: File.open('spec/fixtures/person/test_picture.jpg'))

      expect(helper.header_logo_css).to eql("<style>header.logo a.logo-image { background-image: url(#{asset_path(parent.logo)}); }</style>")
    end

    it 'should return nil when not viewing a group' do
      assign(:group, nil)

      expect(helper.header_logo_css).to be nil
    end

    it 'should return nil when no logo is set' do
      expect(helper.header_logo_css).to be nil
    end
  end
end
