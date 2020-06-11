#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::MailingListsController do
  let(:group)         { groups(:bottom_layer_one) }
  let(:top_leader)    { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  it 'may not index person abos if we do not have no show_detail permission' do
    sign_in(bottom_member)
    expect do
      get :index, params: { group_id: groups(:top_group).id, person_id: top_leader.id }
    end.to raise_error(CanCan::AccessDenied)
  end

  it 'may index my own abos' do
    mailing_lists(:leaders).subscriptions.create!(subscriber: top_leader)

    sign_in(top_leader)
    get :index, params: { group_id: groups(:top_group).id, person_id: top_leader.id }
    expect(assigns(:mailing_lists)).to have(1).items
  end
end
