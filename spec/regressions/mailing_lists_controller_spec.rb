# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
