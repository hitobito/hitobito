# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Quicksearch", sphinx: true do

  sphinx_environment(:people, :groups, :events) do
    it "finds people and groups", js: true do
      obsolete_node_safe do
        index_sphinx
        sign_in
        visit root_path

        fill_in "quicksearch", with: "top"

        dropdown = find(".typeahead.dropdown-menu")
        expect(dropdown).to have_content("Top Leader, Supertown")
        expect(dropdown).to have_content("Top > TopGroup")
        expect(dropdown).to have_content("Top")
        expect(dropdown).to have_content("Top: Top Course (TOP-007)")
      end
    end
  end
end
