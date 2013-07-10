# encoding: UTF-8
require 'spec_helper_request'

describe "Person Autocomplete" do

  subject { page }
  let(:group) { groups(:top_group) }

  it "knows about visibility of dropdown menu", js: true do
    obsolete_node_safe do
      sign_in
      visit root_path
      page.should have_content("TopGroup")
      page.should have_content("Personen")
      click_link 'Personen'
      should have_content ' Person hinzufügen'
      find('.dropdown-menu').should_not be_visible
      click_link 'Person hinzufügen'
      find('.dropdown-menu').should be_visible
      within(:css, '.dropdown-menu') do
        click_link 'Leader'
      end
      should have_content 'Leader erstellen'
    end
  end

  context "highlights content in typeahead", js: true do
    it "for regular queries" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        page.should have_content("Leader erstellen")

        fill_in "Person", with: "gibberish"
        page.should_not have_selector('.typeahead.dropdown-menu')

        fill_in "Person", with: "Top"
        find('.typeahead.dropdown-menu li').should have_content 'Leader Top'
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Top')
      end
    end

    it "for two word queries" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        fill_in "Person", with: "Top Super"
        sleep(0.5)
        find('.typeahead.dropdown-menu li').should have_content 'Leader Top'
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Top')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Super')
      end
    end

    it "for queries with weird spaces" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        fill_in "Person", with: "Top  Super "
        sleep(0.5)
        find('.typeahead.dropdown-menu li').should have_content 'Leader Top'
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Top')
        find('.typeahead.dropdown-menu li').should have_selector('strong', text: 'Super')
      end
    end

    it "saves content from typeahead" do
      obsolete_node_safe do
        sign_in
        visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })

        # search name only
        fill_in "Person", with: "Top"
        find('.typeahead.dropdown-menu li').should have_content 'Leader Top'
        find('.typeahead.dropdown-menu li').click

        click_button 'Speichern'
        should have_content 'Rolle Leader für Leader Top in TopGroup wurde erfolgreich erstellt.'
      end
    end

  end

end
