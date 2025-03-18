# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "PeopleFilter", js: true do
  let(:lang) { :de }
  let(:top_leader) { people(:top_leader) }
  let(:alice) { people(:bottom_member) }

  context "filtering" do
    let(:path) { new_group_people_filter_path(group_id: Group.first.id) }
    before {
      sign_in(top_leader)
      alice.tag_list.add("lorem")
      alice.tag_list.add("ipsum")
      alice.save!

      visit path
      find(".btn.dropdown-toggle").click
    }

    context "tags" do
      before {
        find("#dropdown-option-tag").click
      }

      it "can filter by present tags" do
        expect(page).to have_selector("div#tag-configuration")
        find("#present-tag-select-ts-control").set("lorem")
        find("#present-tag-select-opt-2").click

        first(".btn.btn-primary", text: "Suchen").click
        within(".table.table-striped.table-hover") do
          # Head table row and table row of found user
          expect(all("tr").size).to eq(2)
          expect(page).to have_selector("#person_#{alice.id}")
        end
      end

      it "can filter by absent tags" do
        visit path
        find(".btn.dropdown-toggle").click
        find("#dropdown-option-tag").click
        expect(page).to have_selector("div#tag-configuration")
        find("#absent-tag-select-ts-control").set("ipsum")
        find("#absent-tag-select-opt-1").click

        first(".btn.btn-primary", text: "Suchen").click
        expect(page).to have_no_selector(".table.table-striped.table-hover")
        expect(page).to have_no_selector("#person_#{alice.id}")
      end
    end

    context "roles" do
      before {
        find("#dropdown-option-role").click
      }

      it "can filter by present roles" do
        expect(page).to have_selector("div#role-configuration")
        # Select role
        find("#role-select-ts-control").set(alice.roles.first.label)
        find("#role-select-opt-2").click

        # Select date
        find("#filters_role_start_at").set("2025-03-18")
        find("#filters_role_finish_at").set("2025-03-30")

        # Select role kind
        find("#role-kind-select-ts-control").set("Aktiv")
        find("#role-kind-select-opt-1").click

        first(".btn.btn-primary", text: "Suchen").click
        within(".table.table-striped.table-hover") do
          # Head table row and table row of found user
          expect(all("tr").size).to eq(2)
          expect(page).to have_selector("#person_#{alice.id}")
        end
      end
    end

    context "qualification" do
      before {
        find("#dropdown-option-qualification").click
      }

      it "can filter by qualifications" do
        expect(page).to have_selector("div#qualification-configuration")

        # Select qualification
        find("#qualification-select-ts-control")
          .set(alice.qualifications.first.qualification_kind.label)
        find("#qualification-select-opt-4").click

        # Select reference date
        find("#filters_qualification_reference_date").set("2025-03-05")

        first(".btn.btn-primary", text: "Suchen").click
        within(".table.table-striped.table-hover") do
          # Head table row and table row of found user
          expect(all("tr").size).to eq(2)
          expect(page).to have_selector("#person_#{alice.id}")
        end
      end
    end

    context "attributes" do
      before {
        find("#dropdown-option-attributes").click
      }

      it "can filter by attributes" do
        expect(page).to have_selector("div#attributes-configuration")

        select "PLZ", from: "attribute_filter"
        first(".attribute_constraint_dropdown").find("option[value='equal']").select_option
        first("input.form-control[type='text']").set(alice.zip_code)

        select "Vorname", from: "attribute_filter"
        all(".attribute_constraint_dropdown")[1].find("option[value='equal']").select_option
        all("input.form-control[type='text']")[1].set(alice.first_name)

        first(".btn.btn-primary", text: "Suchen").click
        within(".table.table-striped.table-hover") do
          # Head table row and table row of found user
          expect(all("tr").size).to eq(2)
          expect(page).to have_selector("#person_#{alice.id}")
        end
      end

      it "is xss-attack immune" do
        expect(page).to have_selector("div#attributes-configuration")

        select "Ort", from: "attribute_filter"
        first(".attribute_constraint_dropdown").find("option[value='match']").select_option
        first("input.form-control[type='text']").set("<script>alert('Hacked!');</script>")

        first(".btn.btn-primary", text: "Suchen").click
        expect {
          page.driver.browser.switch_to.alert
        }.to raise_error(Selenium::WebDriver::Error::NoSuchAlertError)
      end
    end
  end

  # context "member access" do
  #   let(:path) { group_people_path(group_id: Group.first.id) }
  #   before {
  #     sign_in(alice)
  #     visit path
  #   }
  #
  #
  # end
end
