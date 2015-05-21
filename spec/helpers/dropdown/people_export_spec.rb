# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Dropdown::PeopleExport' do

  include FormatHelper
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
    is_expected.to have_content 'Export'
    is_expected.to have_selector 'ul.dropdown-menu'
    is_expected.to have_selector 'a' do |tag|
      expect(tag).to have_content 'CSV'
      expect(tag).not_to have_selector 'ul.dropdown-submenu'
    end
    is_expected.to have_selector 'a' do |tag|
      expect(tag).to have_content 'Etiketten'
      expect(tag).to have_selector 'ul.dropdown-submenu' do |pdf|
        expect(pdf).to have_content 'Standard'
      end
    end
    is_expected.to have_selector 'a' do |tag|
      expect(tag).to have_content 'E-Mail Adressen'
    end
  end
end
