# encoding:  utf-8

require 'spec_helper'

describe PeopleController, type: :controller do
  include CrudTestHelper

  before { sign_in(leader) } 

  let(:group) { groups(:top_group) }
  let(:leader) { people(:top_leader) }
  let(:test_entry) { leader }
  let(:test_entry_attrs) { { first_name: 'foo', last_name: 'bar' } }


  def scope_params
    { group_id: group.id }
  end


  include_examples 'crud controller', skip: [%w(index), %w(new), %w(create), %w(destroy)]


end
