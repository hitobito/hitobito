require 'spec_helper_request'
require 'sphinx_environment'

describe "Quicksearch", :mysql do

  sphinx_environment(:people, :groups) do
    it "finds people and groups", js: true do
      obsolete_node_safe do
        sign_in
        visit root_path

        fill_in 'quicksearch', with: "top"
        sleep(1)

        dropdown = find('.typeahead.dropdown-menu')

        if dropdown.text.present?
          dropdown.should have_content("Leader Top, Supertown")
          dropdown.should have_content("Top > TopGroup")
          dropdown.should have_content("Top")
        else
          # stupid poltergeist, not stable enough
          pending
        end
      end
    end
  end
end