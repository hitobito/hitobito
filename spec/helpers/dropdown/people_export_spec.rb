# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Dropdown::PeopleExport' do

  include StandardHelper
  include LayoutHelper

  let(:user) { people(:top_leader) }
  let(:dropdown) do
    Dropdown::PeopleExport.new(self,
                               user,
                               { controller: 'people', group_id: groups(:top_group).id },
                               false,
                               true)
  end

  subject { dropdown.to_s }

  def can?(*args)
    true
  end

  it 'renders dropdown' do
    should have_content 'Export'
    should have_selector 'ul.dropdown-menu'
    should have_selector 'a' do |tag|
      tag.should have_content 'CSV'
      tag.should_not have_selector 'ul.dropdown-submenu'
    end
    should have_selector 'a' do |tag|
      tag.should have_content 'Etiketten'
      tag.should have_selector 'ul.dropdown-submenu' do |pdf|
        pdf.should have_content 'Standard'
      end
    end
    should have_selector 'a' do |tag|
      tag.should have_content 'E-Mail Adressen'
    end
  end
end
