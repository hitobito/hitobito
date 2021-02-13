# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::HistoryController do

  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  describe "GET #index" do

    context "all roles" do

      it "all group roles ordered by group and layer" do
        person = Fabricate(:person)
        r1 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: person)
        r2 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one), person: person, created_at: Date.today - 3.years, deleted_at: Date.today - 2.years)
        r3 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: person)
        r4 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one_one), person: person)

        get :index, params: { group_id: groups(:bottom_group_one_one).id, id: person.id }

        expect(assigns(:roles)).to eq([r1, r4, r2, r3])
      end
    end

  end

end
