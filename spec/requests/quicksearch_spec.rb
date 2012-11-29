require 'spec_helper_request'
require 'sphinx_environment'

describe "Quicksearch", :mysql do
  
  sphinx_environment(:people, :groups) do
    it "finds people and groups", js: true do
      obsolete_node_safe do
        sign_in
        visit root_path
        
        fill_in 'quicksearch', with: "top"
        
        # stupid fallback code for slow processors
        dropdown = find('.typeahead.dropdown-menu')
        if dropdown.text.blank?
          sleep(1)
          dropdown = find('.typeahead.dropdown-menu')
          if dropdown.text.blank?
            sleep(3)
            dropdown = find('.typeahead.dropdown-menu')
          end
        end
        
        dropdown.should have_content("Top Leader, Supertown")
        dropdown.should have_content("Top > TopGroup")
        dropdown.should have_content("Top")
      end
    end
  end
end