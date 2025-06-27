#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeopleController, js: true do
  let(:group) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }
  let(:alice) { people(:bottom_member) }

  it "may define role filter, display and edit it again" do
    member = people(:bottom_member)
    leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two)).person
    Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two))

    obsolete_node_safe do
      sign_in_and_create_filter

      find("#filters_role_role_type_ids_#{Group::BottomLayer::Leader.id}").set(true)
      find("#filters_role_role_type_ids_#{Group::BottomLayer::Member.id}").set(true)
      fill_in("people_filter_name", with: "Bottom Layer")
      all("form .btn-toolbar").first.click_button("Suche speichern")

      expect(page).to have_selector(".table tbody tr", count: 2)
      expect(page).to have_selector("#person_#{leader.id}")
      expect(page).to have_selector("#person_#{member.id}")

      # edit the current filter
      click_link "Bottom Layer"
      click_link "Neuer Filter..."

      # roles accordion is already open
      expect(page).to have_selector(".accordion-body", count: 1)

      expect(page).to have_checked_field("filters_role_role_type_ids_#{Group::BottomLayer::Leader.id}")
      expect(page).to have_checked_field("filters_role_role_type_ids_#{Group::BottomLayer::Member.id}")

      find("#filters_role_role_type_ids_#{Group::BottomLayer::Member.id}").set(false)
      all("form .btn-toolbar").first.click_button("Suchen")

      expect(page).to have_selector(".table tbody tr", count: 1)
      expect(page).to have_selector("tr#person_#{leader.id}")

      # open the previously defined filter again
      click_link "Eigener Filter"
      click_link "Bottom Layer"

      # roles accordion is already open
      expect(page).to have_selector(".table tbody tr", count: 2)

      # open other tab
      click_link "Externe"
      expect(page).to have_no_selector(".table-striped tbody tr")
    end
  end

  context "toggling roles" do
    it "toggles roles when clicking layer" do
      obsolete_node_safe do
        sign_in_and_create_filter

        find("h4.filter-toggle", text: "Top Layer").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 8)

        find("h4.filter-toggle", text: "Top Layer").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 0)
      end
    end

    it "toggles roles when clicking group" do
      obsolete_node_safe do
        sign_in_and_create_filter

        find("h5.filter-toggle", text: "Top Group").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 7)

        find("h5.filter-toggle", text: "Top Group").click
        expect(page).to have_css("#roles input[name='filters[role][role_type_ids][]']:checked", count: 0)
      end
    end
  end

  context "attributes" do
    before do
      sign_in
      visit group_people_path(group, range: "layer")

      click_link "Weitere Ansichten"
      click_link "Neuer Filter..."
      expect(page).to have_content "Personen filtern"

      find(".btn.dropdown-toggle").click
      click_link "Felder"
    end

    it "supports filtering by specific attribute on person" do
      choose "In der aktuellen Ebene und allen darunter liegenden Ebenen und Gruppen"
      select "Nachname"
      option = select "ist genau"
      value_id = option.send(:parent)["id"].gsub("constraint", "value")
      fill_in(value_id, with: "Leader")
      first(:button, "Suchen").click
      expect(page).to have_css "td", text: "Leader Top"
      expect(page).not_to have_css "td", text: "Member Bottom"
    end

    it "removes value field when selecting blank constraint" do
      find("#attribute_filter option", text: "Nachname").click
      find(".attribute_constraint_dropdown option", text: "ist leer").click
      expect(page).not_to have_css ".attribute_value_input"
    end

    it "has country select dropdown for country attrs" do
      find("#attribute_filter option", text: "Land").click
      expect(page).to have_css ".country_select_field"
    end

    it "has integer type field for number fields" do
      find("#attribute_filter option", text: "Alter").click
      expect(page).to have_css ".integer_field"
    end

    it "has date field for date attrs" do
      find("#attribute_filter option", text: "Geburtstag").click
      expect(page).to have_css ".date_field"
    end

    it "has gender field for gender attrs" do
      find("#attribute_filter option", text: "Geschlecht").click
      expect(page).to have_css ".gender_select_field"
    end
  end

  def sign_in_and_create_filter
    sign_in
    visit group_people_path(group)
    expect(page).to have_no_selector(".table tbody tr")

    find(".dropdown-toggle", text: "Weitere Ansichten").click
    find(".dropdown-item", text: "Neuer Filter...").click
    find(".accordion-button", text: "Rollen").click

    expect(page).to have_css("#roles .label-columns input:checked", count: 0)
  end

  context "filtering" do
    let(:path) { new_group_people_filter_path(group_id: Group.first.id) }

    before {
      sign_in(top_leader)
      visit path
      find(".btn.dropdown-toggle").click
    }

    context "tags" do
      before {
        alice.tag_list.add("lorem")
        alice.tag_list.add("ipsum")
        alice.save!
        find("#dropdown-option-tag").click
      }

      it "can filter by present tags" do
        expect(page).to have_selector("div#tag-configuration")
        find("#present-tag-select-ts-control").set("lorem")
        find("#present-tag-select-opt-2").click

        first(".btn.btn-primary", text: "Suchen").click
        expect(page).to have_text(alice.first_name)
      end

      it "can filter by absent tags" do
        visit path
        find(".btn.dropdown-toggle").click
        find("#dropdown-option-tag").click
        expect(page).to have_selector("div#tag-configuration")
        find("#absent-tag-select-ts-control").set("ipsum")
        find("#absent-tag-select-opt-1").click

        first(".btn.btn-primary", text: "Suchen").click
        expect(page).to have_text(alice.first_name)
      end
    end

    context "roles" do
      before {
        find("#dropdown-option-role").click
      }

      it "can filter by present roles" do
        expect(page).to have_selector("div#role-configuration")
        # Select role
        find("#role-select-ts-control").set(alice.roles.first.type.split(":").last)
        find("#role-select-opt-3").click

        # Select date
        find("#filters_role_start_at").set("2025-03-18")
        find("#filters_role_finish_at").set("2025-03-30")

        # Select role kind
        find("#role-kind-select").set("Aktiv")

        first(".btn.btn-primary", text: "Suchen").click
        expect(page).to have_text(alice.first_name)
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

        expect(page).to have_text(alice.first_name)
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
        expect(page).to have_text(alice.first_name)
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

    context "saving" do
      let(:path) { new_group_people_filter_path(group_id: Group.first.id) }

      before {
        sign_in(top_leader)
        visit path
        find(".btn.dropdown-toggle").click
      }

      it "can save filter" do
        find("#dropdown-option-role").click

        find("#role-select-ts-control").click
        find("#role-select-opt-1").click

        filter_name = "Filtername"
        fill_in "people_filter_name", with: filter_name
        first(".btn.btn-primary", text: "Suchen").click
        check("save-filter")
        expect(page).to have_text(filter_name.to_s)
      end
    end
  end

  context "member access" do
    let(:path) { new_group_people_filter_path(group_id: Group.find_by(name: "Top").id) }

    before {
      Rails.env.stub(production?: true)
      sign_in(alice)
    }

    it "can't access people filtering" do
      visit path
      expect(page).to have_text("Sie sind nicht berechtigt, diese Seite anzuzeigen")
    end
  end
end
