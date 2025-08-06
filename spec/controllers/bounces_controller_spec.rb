# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe BouncesController do
  context "nested in a Mailinglist" do
    describe "GET #index" do
      it "is allowed if I am admin" do
        sign_in(people(:top_leader))
        get :index, params: {group_id: groups(:top_layer), mailing_list_id: mailing_lists(:leaders)}

        expect(response).to be_ok
      end

      it "is allowed if I can edit the mailing-list" do
        group = groups(:bottom_layer_one)
        person = Fabricate(Group::BottomLayer::Leader.sti_name.to_sym, group: group).person
        mailing_list = Fabricate(:mailing_list, group: group)

        sign_in(person)
        get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}

        expect(response).to be_ok
      end

      it "is not allowed if I am neither an admin nor can edit the list" do
        sign_in(people(:bottom_member))

        expect do
          get :index, params: {group_id: groups(:top_layer), mailing_list_id: mailing_lists(:leaders)}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
