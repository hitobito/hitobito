
require 'spec_helper_request'

describe PeopleController, js: true do

  let(:group) { groups(:top_layer) }

  it 'may define role filter, display and edit it again' do
    member = people(:bottom_member)
    leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two)).person
    Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two))

    obsolete_node_safe do
      sign_in
      visit group_people_path(group)

      page.should_not have_selector('.table tbody tr')

      # create a new filter
      click_link 'Weitere Ansichten'
      click_link 'Neuer Filter...'

      find("#people_filter_role_type_ids_#{Group::BottomLayer::Leader.id}").set(true)
      find("#people_filter_role_type_ids_#{Group::BottomLayer::Member.id}").set(true)
      fill_in('people_filter_name', with: 'Bottom Layer')
      click_button 'Suche speichern'

      page.should have_selector('.table tbody tr', count: 2)
      page.should have_selector("#person_#{leader.id}")
      page.should have_selector("#person_#{member.id}")

      # edit the current filter
      click_link 'Bottom Layer'
      click_link 'Neuer Filter...'

      page.should have_checked_field("people_filter_role_type_ids_#{Group::BottomLayer::Leader.id}")
      page.should have_checked_field("people_filter_role_type_ids_#{Group::BottomLayer::Member.id}")

      find("#people_filter_role_type_ids_#{Group::BottomLayer::Member.id}").set(false)
      click_button 'Suchen'

      page.should have_selector('.table tbody tr', count: 1)
      page.should have_selector("tr#person_#{leader.id}")

      # open the previously defined filter again
      click_link 'Eigener Filter'
      click_link 'Bottom Layer'

      page.should have_selector('.table tbody tr', count: 2)

      # open other tab
      click_link 'Externe'
      should_not have_selector('.table-striped tbody tr')
    end
  end
end
