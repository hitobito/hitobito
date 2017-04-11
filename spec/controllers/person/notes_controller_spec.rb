# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

require 'spec_helper'

describe Person::NotesController do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before { sign_in(top_leader) }

  describe 'GET #index' do
    let(:group) { groups(:top_layer) }
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }

    it 'assignes all notes of layer' do
      n1 = Person::Note.create!(author: top_leader, person: top_leader, text: 'lorem')
      _n2 = Person::Note.create!(author: top_leader, person: bottom_member, text: 'ipsum')
      get :index, id: group.id

      expect(assigns(:notes)).to eq([n1])
    end
  end

  describe 'POST #create' do
    it 'creates person notes' do
      expect do
        post :create, group_id: bottom_member.groups.first.id,
                      person_id: bottom_member.id,
                      person_note: { text: 'Lorem ipsum' }
      end.to change { Person::Note.count }.by(1)

      expect(assigns(:note).text).to eq('Lorem ipsum')
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end
  end

  describe 'POST #destroy' do
    it 'destroys person note' do
      n = Person::Note.create!(author: top_leader, person: top_leader, text: 'lorem')
      expect do
        post :destroy, group_id: n.person.groups.first.id,
                       person_id: n.person.id,
                       id: n.id,
                       format: :js
      end.to change { Person::Note.count }.by(-1)
    end
  end

end
