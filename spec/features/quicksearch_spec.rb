# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'sphinx_environment'

describe 'Quicksearch', :mysql do

  sphinx_environment(:people, :groups) do
    it 'finds people and groups', js: true do
      index_sphinx
      obsolete_node_safe do
        sign_in
        visit root_path

        fill_in 'quicksearch', with: 'top'

        dropdown = find('.typeahead.dropdown-menu')
        dropdown.should have_content('Top Leader, Supertown')
        dropdown.should have_content('Top > TopGroup')
        dropdown.should have_content('Top')
      end
    end
  end
end
