# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Person::MessagesController do
  let(:message) { messages(:simple) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context "GET index" do
    it "shows messages of herself" do
      sign_in(top_leader)

      get :index, params: {id: top_leader.id, group_id: top_leader.primary_group_id}

      expect(assigns(:messages)).to eq([message])
    end

    it "shows messages with index_messages permission on person" do
      MessageRecipient.create!(message: message, person: bottom_member)
      sign_in(top_leader)

      expect(controller.current_ability).to be_able_to(:index_messages, bottom_member)

      get :index, params: {id: bottom_member.id, group_id: bottom_member.primary_group_id}

      expect(assigns(:messages)).to eq([message])
    end

    it "raises without index_messages permission on person" do
      sign_in(bottom_member)

      expect(controller.current_ability).not_to be_able_to(:index_messages, top_leader)

      expect do
        get :index, params: {id: top_leader.id, group_id: top_leader.primary_group_id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
