require 'spec_helper'

describe AddressesController, js: true do
  it 'finds address, fills form fields and finds number' do
    obsolete_node_safe do
      index_sphinx
      sign_in
      member = people(:bottom_member)

      visit edit_group_person_path(member.groups.first, member)

      fill_in 'person_address', with: 'Belp'

      dropdown = find('.typeahead.dropdown-menu')
      expect(dropdown).to have_content('Belpstrasse 3007 Bern')
      expect(dropdown).to have_content('Belpstrasse 3007 Muri b. Bern')

      find('.typeahead.dropdown-menu li', text: 'Belpstrasse 3007 Bern').click

      expect(page).to have_field('person_zip_code', with: '3007')
      expect(page).to have_field('person_town', with: 'Bern')
      expect(page).to have_field('person_address', with: 'Belpstrasse ')

      fill_in 'person_address', with: 'Belpstrasse 4'
      dropdown = find('.typeahead.dropdown-menu')
      expect(dropdown).to have_content('Belpstrasse 40 Bern')
      expect(dropdown).to have_content('Belpstrasse 41 Bern')

      find('.typeahead.dropdown-menu li', text: 'Belpstrasse 41 Bern').click
      expect(page).to have_field('person_address', with: 'Belpstrasse 41')
      expect(page).to have_field('person_zip_code', with: '3007')
      expect(page).to have_field('person_town', with: 'Bern')
    end
  end

  it 'shows no typeahead on non supported country' do
    obsolete_node_safe do
      index_sphinx
      sign_in
      member = people(:bottom_member)

      visit edit_group_person_path(member.groups.first, member)

      find('#person_country_chosen').click
      find('#person_country_chosen ul.chosen-results li.active-result', text: 'Vereinigte Staaten').click

      fill_in 'person_address', with: 'Belp'

      expect(page).to_not have_css('.typeahead.dropdown-menu')
    end
  end
end
