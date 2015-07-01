# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::KindsController do

  let(:destroyed) { Event::Kind.with_deleted.find(ActiveRecord::FixtureSet.identify(:old)) }

  before { sign_in(people(:top_leader)) }

  it 'POST update resets destroy flag when updating deleted kinds' do
    expect(destroyed).to be_destroyed
    post :update, id: destroyed.id, event_kind: { label: destroyed.label }
    expect(destroyed.reload).not_to be_destroyed
  end

  it 'GET index lists destroyed entries last' do
    get :index
    expect(assigns(:kinds).last).to eq(destroyed)
  end

  it 'POST create accepts qualification_conditions and general_information' do
    post :create, event_kind: { label: 'Foo',
                                application_conditions: '<b>bar</b>',
                                general_information: '<b>baz</b>' }

    kind = assigns(:kind)
    expect(kind.reload.application_conditions).to eq '<b>bar</b>'
    expect(kind.general_information).to eq '<b>baz</b>'
  end

  context 'qualification kinds' do
    let(:sl) { qualification_kinds(:sl) }
    let(:gl) { qualification_kinds(:gl) }
    let(:ql) { qualification_kinds(:ql) }
    let(:kind) { event_kinds(:fk) }

    it 'creates event kind without associations' do
      post :create, event_kind: { label: 'Foo' }

      expect(assigns(:kind).errors.full_messages).to eq []

      assocs = assigns(:kind).event_kind_qualification_kinds
      expect(assocs.count).to eq 0
    end

    it 'adds associations to new event kind' do
      post :create, event_kind: { label: 'Foo',
                                  qualification_kinds: {
                                    participant: {
                                      precondition: { qualification_kind_ids: [sl.id, gl.id] },
                                      qualification: { qualification_kind_ids: [sl.id, gl.id] },
                                      prolongation: { qualification_kind_ids: [sl.id] }
                                    },
                                    leader: {
                                      qualification: { qualification_kind_ids: [sl.id, gl.id] },
                                      prolongation: { qualification_kind_ids: [sl.id, gl.id] }
                                    }
                                  }
                                }

      expect(assigns(:kind).errors.full_messages).to eq []

      assocs = assigns(:kind).event_kind_qualification_kinds
      expect(assocs.count).to eq 9
      expect(assocs.where(role: :participant, category: :precondition).count).to eq 2
      expect(assocs.where(role: :participant, category: :qualification).count).to eq 2
      expect(assocs.where(role: :participant, category: :prolongation).count).to eq 1
      expect(assocs.where(role: :leader, category: :qualification).count).to eq 2
      expect(assocs.where(role: :leader, category: :prolongation).count).to eq 2
    end

    it 'adds association to existing event kind' do
      expect(kind.event_kind_qualification_kinds.count).to eq 4
      ids = kind.event_kind_qualification_kinds.pluck(:qualification_kind_id)
      ids << ql.id

      put :update, id: kind.id, event_kind: { label: kind.label,
                                              qualification_kinds: { participant: { prolongation: {
                                                qualification_kind_ids: ids } } } }

      assocs = assigns(:kind).event_kind_qualification_kinds
      expect(assocs.count).to eq 5
      expect(assocs.pluck(:qualification_kind_id)).to match_array(ids)
    end

    it 'removes association from existing event kind' do
      expect(kind.event_kind_qualification_kinds.count).to eq 4

      put :update, id: kind.id, event_kind: { label: kind.label,
                                              qualification_kinds: { participant: { prolongation: {
                                                qualification_kind_ids: [gl.id] } } } }

      assocs = assigns(:kind).event_kind_qualification_kinds
      expect(assocs.count).to eq 1
      expect(assocs.pluck(:qualification_kind_id)).to match_array([gl.id])
    end

    it 'removes all associations from existing event kind' do
      expect(kind.event_kind_qualification_kinds.count).to eq 4

      put :update, id: kind.id, event_kind: { label: kind.label,
                                              qualification_kinds: { participant: { prolongation: {
                                                qualification_kind_ids: [] } } } }

      assocs = assigns(:kind).event_kind_qualification_kinds
      expect(assocs.count).to eq 0
    end

  end


end
