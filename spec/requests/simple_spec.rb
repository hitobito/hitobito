# encoding: UTF-8
require 'spec_helper_request'

describe "" do

  subject { page }
  let(:group) { groups(:top_group) }

  it "knows about visibility of dropdown menu", js: true do
    sign_in 'top_leader@example.com', 'foobar'
    visit root_path
    page.body.should include("TopGroup")
    click_link 'TopGroup'
    should have_content ' Person hinzufügen'
    find('.dropdown-menu').should_not be_visible
    click_link 'Person hinzufügen'
    find('.dropdown-menu').should be_visible
  end


  it "verifies content in typeahead", js: true do
    sign_in 'top_leader@example.com', 'foobar'
    visit new_group_role_path(group, role: { type: 'Group::TopGroup::Leader' })
    find('.typeahead.dropdown-menu').should_not have_content 'Top Leader'
    fill_in "Person", with: "Top"
    find('.typeahead.dropdown-menu').should have_content 'Top Leader'
  end

end
