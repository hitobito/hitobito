# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe :datepicker, js: true do
  context "Datepicker" do
    before do
      sign_in(people(:root))
      visit list_courses_path # any path with datepicker is possible
    end

    it "it is possible to use format dd.mm.yyyy" do
      fill_in "#filter_since", with: "01.01.1980"
    end

    it "locale does not change date picker format" do
      click_on "FR"
      fill_in "#filter_since", with: "01.01.1980"
    end
  end
end
