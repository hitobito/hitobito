# encoding:  utf-8

require 'spec_helper'

describe MailingListsController, type: :controller do

  let(:group) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }

  def scope_params
    { group_id: group.id }
  end

  let(:test_entry) { mailing_lists(:leaders) }
  let(:test_entry_attrs) do
     { name: 'Test mailing list', 
       description: 'Bla bla bla',
       publisher: 'Me & You',
       mail_name: 'tester',
       subscribable: true,
       subscribers_may_post: false }
   end

  before do
    sign_in(people(:top_leader)) 
  end

  include_examples 'crud controller'

end
