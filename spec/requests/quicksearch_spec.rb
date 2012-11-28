require 'spec_helper_request'
require 'sphinx_environment'

describe "Quicksearch", :mysql do
  
  sphinx_environment(:people, :groups) do
    it "finds people and groups", js: true do
      sign_in
      visit root_path
      
      fill_in 'quicksearch', with: "top"
      sleep(2)
      
      dropdown = find('.typeahead.dropdown-menu')
      dropdown.should have_content("Top Leader, Supertown")
      dropdown.should have_content("Top > TopGroup")
      dropdown.should have_content("Top")
    end
  end
end