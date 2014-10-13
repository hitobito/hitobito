# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Dropdown::GroupAdd' do

  include StandardHelper
  include LayoutHelper

  let(:group) { groups(:top_layer) }
  let(:dropdown) { Dropdown::GroupAdd.new(self, group)}

  subject { dropdown.to_s }

  def can?(*args)
    true
  end

  it 'renders dropdown' do
    should have_content 'Gruppe erstellen'
    should have_selector 'ul.dropdown-menu'
    should have_selector 'a' do |tag|
      tag.should have_content 'Group::TopGroup'
    end
    should have_selector 'a' do |tag|
      tag.should have_content 'Group::BottomLayer'
    end
  end
end
