# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MessagesController do
  let(:list)       { mailing_lists(:leaders) }
  let(:nesting)    { { group_id: list.group_id, mailing_list_id: list.id } }
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'GET#index' do
    it 'is present for current year' do
      get :index, params: nesting
      expect(assigns(:messages)).to be_present
    end

    it 'is empty for previous year' do
      travel_to 1.year.ago do
        get :index, params: nesting
      end
      expect(assigns(:messages)).to be_empty
    end
  end

  it 'GET#new builds new Letter and sets recipient count' do
    Fabricate(:subscription, mailing_list: list, subscriber: top_leader)
    get :new, params: nesting.merge(message: { type: 'Message::Letter' })
    expect(assigns(:message)).to be_kind_of(Message::Letter)
    expect(assigns(:recipient_count)).to eq 1
  end

  it 'POST#create saves Letter' do
    post :create, params: nesting.merge(
      message: { subject: 'Mitgliedsbeitrag', type: 'Message::Letter' }
    )
    expect(assigns(:message)).to be_persisted
    expect(response).to redirect_to group_mailing_list_message_path(id: assigns(:message).id)
  end
end
