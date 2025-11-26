# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "Datepicker", js: true do
  let(:lang) { :de }
  let(:person) { people(:root) }

  before do
    allow(Settings.application).to receive(:languages).and_return({de: "Deutsch", fr: "Français"})
    sign_in(person)
    visit list_courses_path(locale: lang) # any path with datepicker is possible
  end

  [:de, :fr].each do |l|
    context "with lang set to #{l}" do
      let(:lang) { l }

      it "does not change date picker format" do
        find("#filter_since").click
        click_on(Time.zone.today.day.to_s)
        expect(find("#filter_since").value).to eq(Time.zone.today.strftime("%d.%m.%Y"))
      end
    end
  end
end
