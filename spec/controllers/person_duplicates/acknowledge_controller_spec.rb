# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PersonDuplicates::AcknowledgeController do

    let(:layer) { groups(:bottom_layer_one) }
    let(:layer_leader) { Fabricate('Group::BottomLayer::Leader', group: layer).person }
    let(:person_1) { Fabricate('Group::BottomGroup::Member', group: groups(:bottom_group_one_one)).person }
    let(:person_2) { Fabricate('Group::BottomGroup::Member', group: groups(:bottom_group_one_one)).person }
    let!(:duplicate_entry) { PersonDuplicate.create!(person_1: person_1, person_2: person_2) }

    context '#new' do
      it 'access acknowledge confirm dialog' do
        sign_in(layer_leader)

        post :new, xhr: true, params: { group_id: layer.id, id: duplicate_entry.id }

        expect(response.status).to eq 200
      end

      it 'is not possible to access confirm dialog without write permission on at least one person' do
        sign_in(people(:top_leader))

        expect { post :new, xhr: true, params: { group_id: layer.id, id: duplicate_entry.id } }.to raise_error(CanCan::AccessDenied)

        expect(duplicate_entry.reload.acknowledged).to eq(false)
      end

      it 'is not possible access confirm dialog  without permission to manage person duplicates' do
        sign_in(people(:bottom_member))

        expect { post :create, xhr: true, params: { group_id: layer.id, id: duplicate_entry.id } }.to raise_error(CanCan::AccessDenied)

        expect(duplicate_entry.reload.acknowledged).to eq(false)
      end
    end

    context '#create' do
      it 'acknowledges duplicate entry' do
        sign_in(layer_leader)

        post :create, xhr: true, params: { group_id: layer.id, id: duplicate_entry.id }

        expect(response.body).to include('Turbolinks.visit("' + group_person_duplicates_url(layer))

        expect(duplicate_entry.reload.acknowledged).to eq(true)
        expect(flash[:notice]).to eq 'Der Duplikats-Eintrag wurde erfolgreich entfernt.'
      end

      it 'is not possible to acknowledge without write permission on at least one person' do
        sign_in(people(:top_leader))

        expect { post :create, xhr: true, params: { group_id: layer.id, id: duplicate_entry.id } }.to raise_error(CanCan::AccessDenied)

        expect(duplicate_entry.reload.acknowledged).to eq(false)
      end

      it 'is not possible to acknowledge without permission to manage person duplicates' do
        sign_in(people(:bottom_member))

        expect { post :create, xhr: true, params: { group_id: layer.id, id: duplicate_entry.id } }.to raise_error(CanCan::AccessDenied)

        expect(duplicate_entry.reload.acknowledged).to eq(false)
      end
    end
end
