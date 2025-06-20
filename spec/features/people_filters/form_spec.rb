require "spec_helper"

describe "People Filter Form", js: true do
  let(:person) { people(:root) }
  let(:group) { groups(:top_layer) }

  describe "#create_filter" do
    before do
      sign_in(person)
      visit new_group_people_filter_path(group)
    end

    it "can't save filter without defining name for it" do
      click_button "Filter speichern"
      expect(page).to have_selector(".alert.alert-danger", text: "Name muss ausgefüllt werden")
    end

    it "can save filter after name defined" do
      fill_in "people_filter[name]", with: "Alice"
      click_button "Filter speichern"
      expect(page).to have_selector(".alert.alert-success", text: "Filter Alice wurde erfolgreich erstellt.")
    end
  end

  describe "#edit_filter" do
    before do
      filter = PeopleFilter.create!(
        name: "My Filter",
        range: "deep",
        group_id: group.id,
        filter_chain: {
          qualification: {qualification_kind_ids: [QualificationKind.first.id, QualificationKind.second.id]},
          role: {role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join("-")},
          attributes: {
            timestamp: {
              key: "years",
              constraint: "equal",
              value: 56
            },
            timestamp2: {
              key: "language",
              constraint: "equal",
              value: %w[de en fr]
            }
          }
        }
      )
      filter.save!
      sign_in(person)
      visit edit_group_people_filter_path(group.id, filter.id)
    end

    it "builds view correctly based on filter params" do
      expect(page).to have_selector("h3", text: "Rollen")
      expect(page).to have_selector("h3", text: "Felder")
      expect(page).to have_selector("h3", text: "Qualifikationen")

      # Checks that correct attributes are loaded
      expect(page).to have_text("Alter")
      expect(page).to have_text("Sprache")
    end
  end
end
