# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "Global Conditions", js: true do
  let(:lang) { :de }
  let(:top_leader) { people(:top_leader) }
  let(:alice) { people(:bottom_member) }

  context "modify" do
    let(:path) { edit_group_mailing_list_filter_path(group_id: MailingList.first.group_id,
                                                     mailing_list_id: MailingList.first.id)}
    before {
      sign_in(top_leader)
      visit path
    }

    it "can add global conditions" do
      select "Firmenname", from: "attribute_filter"
      first(".attribute_constraint_dropdown").find("option[value='not_match']").select_option
      first("input.form-control[type='text']").set("Puzzle ITC")

      select "Alter", from: "attribute_filter"
      all(".attribute_constraint_dropdown")[1].find("option[value='equal']").select_option
      all("input.form-control[type='text']")[1].set(56)

      first(".btn.btn-primary", text: "Speichern").click

      within("div#main") do
        expect(page).to have_text("Firmenname enthält nicht Puzzle ITC")
        expect(page).to have_text("Alter ist genau 56")
      end
    end

    context "member access" do
      before {
        Rails.env.stub(:production? => true)
        sign_in(alice)
      }

      it "can't access global conditions" do
        visit path
        expect(page).to have_selector("div.alert-danger", text: "Sie sind nicht berechtigt, diese Seite anzuzeigen")
      end
    end
  end
end
