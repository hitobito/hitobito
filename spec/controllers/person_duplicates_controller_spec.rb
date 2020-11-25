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
    let(:layer_leader) { Fabricate('Group::BottomLayer::Leader', group: layer_one).person }
    # let(:person_1) { Fabricate('Group::BottomGroup::Member', group: groups(:bottom_group_one_one)).person }
    # let(:person_2) { Fabricate('Group::BottomGroup::Member', group: groups(:bottom_group_one_one)).person }
    # let!(:duplicate_entry) { PersonDuplicate.create!(person_1: person_1, person_2: person_2) }

    context '#index' do
      it 'lists all duplicates on top layer' do
        sign_in(top_leader)

        get :index, params: { group_id: top_layer.id }

        expect(response.status).to eq 200
      end

      it 'lists all duplicates on and bellow given layer' do
        sign_in(layer_leader)

        get :index, params: { group_id: layer_one.id }
      end

      it 'is not possible access without permission to manage person duplicates' do
        sign_in(people(:bottom_member))

        expect { get :index, params: { group_id: top_layer.id } }.to raise_error(CanCan::AccessDenied)
      end
    end
end
