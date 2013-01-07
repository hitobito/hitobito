# encoding:  utf-8

require 'spec_helper'

describe MailingListsController, type: :controller do

  let(:group) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }

  def scope_params
    { group_id: group.id }
  end

  let(:test_entry) { mailing_lists(:leaders) }
  let(:test_entry_attrs) { { name: 'Test mailing list' } }

  before do
    sign_in(people(:top_leader)) 
  end

  include_examples 'crud controller'

end
