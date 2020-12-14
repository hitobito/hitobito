# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PersonDuplicatesController do
    let(:top_layer) { groups(:top_layer) }
    let(:top_leader) { people(:top_leader) }
    let(:layer_one) { groups(:bottom_layer_one) }
    let(:bottom_group) { groups(:bottom_group_one_one) }
    let(:layer_leader) { Fabricate('Group::BottomLayer::Leader', group: layer_one).person }
    let!(:duplicate1) { Fabricate(:person_duplicate) }
    let!(:duplicate2) { Fabricate(:person_duplicate) }
    let!(:duplicate3) { Fabricate(:person_duplicate) }
    let!(:duplicate4) { Fabricate(:person_duplicate) }
    let(:entries) { assigns(:person_duplicates) }

    before { assign_people }

    context '#index' do
      it 'lists all duplicates on top layer' do
        sign_in(top_leader)

        get :index, params: { group_id: top_layer.id }

        expect(response.status).to eq 200

        expect(entries.count).to eq(4)
      end

      it 'lists all duplicates on and below given layer' do
        sign_in(layer_leader)

        get :index, params: { group_id: layer_one.id }

        expect(response.status).to eq 200

        expect(entries.count).to eq(3)
        expect(entries).to include(duplicate2)
        expect(entries).to include(duplicate3)
        expect(entries).to include(duplicate4)
      end

      it 'is not possible to list duplicates without permission to manage person duplicates' do
        sign_in(people(:bottom_member))

        expect { get :index, params: { group_id: top_layer.id } }.to raise_error(CanCan::AccessDenied)
      end
    end

    private

    def assign_people
      # duplicate1
      Fabricate('Group::TopLayer::TopAdmin', group: top_layer, person: duplicate1.person_1)
      Fabricate('Group::TopLayer::TopAdmin', group: top_layer, person: duplicate1.person_2)
      
      # duplicate2
      Fabricate('Group::BottomLayer::Member', group: layer_one, person: duplicate2.person_1)
      Fabricate('Group::BottomLayer::Member', group: layer_one, person: duplicate2.person_2)
      
      # duplicate3
      Fabricate('Group::BottomGroup::Member', group: bottom_group, person: duplicate3.person_1)
      Fabricate('Group::TopLayer::TopAdmin', group: top_layer, person: duplicate3.person_2)
      
      # duplicate4
      Fabricate('Group::TopLayer::TopAdmin', group: top_layer, person: duplicate4.person_1)
      Fabricate('Group::BottomLayer::Member', group: layer_one, person: duplicate4.person_2)
    end
end
