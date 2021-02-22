# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::MessagesController do
  let(:message) { messages(:simple) }
  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }

  before { sign_in(top_leader) }

  context "GET index" do
    it "shows messages of person" do
      MessageRecipient.create!(message: message, person: top_leader)

      get :index, params: {id: top_leader.id, group_id: top_group.id}

      expect(assigns(:messages)).to eq([message])
    end
  end
end
