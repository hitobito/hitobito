require 'spec_helper'

describe GroupsController, type: :controller do
  include CrudTestHelper

  before { sign_in(person) } 

  let(:group) { groups(:top_layer) }
  let(:person) { Fabricate(Group::TopLayer::Member.name.to_sym, person: person, group: group).person } 

  let(:test_entry) { group } 
  let(:test_entry_attrs) { create_entry_attrs }
  let(:create_entry_attrs) { {name: 'foo', type: 'Group::TopGroup', parent_id: group.id } }
  let(:update_entry_attrs) { {name: 'bar'} }

  include_examples 'crud controller', skip: [%w(index), %w(new), %w(destroy)]


  describe "happy path for skipped crud views" do
    render_views

    it "#index" do
      get :index
      should redirect_to Group.root
    end

    it "#new" do
      templates = ["shared/_error_messages",
       "contactable/_fields",
       "contactable/_phone_number_fields",
       "contactable/_social_account_fields",
       "groups/_form",
       "crud/new",
       "layouts/_options",
       "layouts/_flash",
       "layouts/application"]

      get :new, group: { parent_id: group.id, type: 'Group::TopGroup' }
      templates.each { |template| should render_template(template) } 
    end
    pending "#destroy"
  end
end
