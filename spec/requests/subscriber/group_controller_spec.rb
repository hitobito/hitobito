require 'spec_helper_request'

describe Subscriber::GroupController, js: true do
  
  let(:list)  { mailing_lists(:leaders) }
  let(:group) { list.group }
  
  it "selects group and loads roles" do
    obsolete_node_safe do
      sign_in
      visit new_group_mailing_list_group_path(group.id, list.id)
      
      find('#roles').should_not have_selector('input[type=checkbox]')
      
      # trigger typeahead
      fill_in "subscription_subscriber", with: "Bottom"
      
      find('.typeahead.dropdown-menu').should have_content('Top > Bottom One')
      find('.typeahead.dropdown-menu').should have_content('Bottom One > Group 11')
      
      # select entry from typeahead
      find(".typeahead.dropdown-menu li a", text: 'Top > Bottom One').click
        
      find('#subscription_subscriber_id').value.should == groups(:bottom_layer_one).id.to_s
      
      find('#roles').should have_selector('input[type=checkbox]', count: 5) # roles
      find('#roles').should have_selector('h5', count: 2) # layers (have same label..)
      
      # check role and submit
      check('subscription_role_types_group::bottomgroup::leader')
      
      click_button 'Speichern'
      
      page.should have_content('Abonnent Bottom One (Rolle) wurde erfolgreich')
    end
  end
end
