# encoding: utf-8

#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe NotesController do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before { sign_in(top_leader) }

  describe 'GET #index' do
    let(:group) { groups(:top_layer) }
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }

    it 'assignes all notes of layer' do
      n1 = Note.create!(author: top_leader, subject: top_leader, text: 'lorem')
      _n2 = Note.create!(author: top_leader, subject: bottom_member, text: 'ipsum')
      get :index, group_id: group.id

      expect(assigns(:notes)).to eq([n1])
    end
  end

  describe 'POST #create' do
    it 'creates person notes' do
      expect do
        post :create, group_id: bottom_member.groups.first.id,
                      person_id: bottom_member.id,
                      note: { text: 'Lorem ipsum' },
                      format: :js
      end.to change { Note.count }.by(1)

      expect(assigns(:note).text).to eq('Lorem ipsum')
      expect(assigns(:note).subject).to eq(bottom_member)
      expect(response.status).to eq(200)
    end

    it 'creates group notes' do
      group = bottom_member.groups.first
      expect do
        post :create, group_id: group.id,
                      note: { text: 'Lorem ipsum' },
                      format: :js
      end.to change { Note.count }.by(1)

      expect(assigns(:note).text).to eq('Lorem ipsum')
      expect(assigns(:note).subject).to eq(group)
      expect(response.status).to eq(200)
      is_expected.to render_template('create')
    end

    it 'redirects for html requests' do
      group = bottom_member.groups.first
      expect do
        post :create, group_id: group.id,
             note: { text: 'Lorem ipsum' }
      end.to change { Note.count }.by(1)
      is_expected.to redirect_to(group_path(group))
    end

    it 'cannot create notes on lower layer' do
      sign_in(Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)).person)

      expect do
        expect do
          post :create, group_id: bottom_member.groups.first.id,
                        person_id: bottom_member.id,
                        note: { text: 'Lorem ipsum' },
                        format: :js
        end.to raise_error(CanCan::AccessDenied)
      end.not_to change { Note.count }
    end
  end

  describe 'POST #destroy' do
    it 'destroys person note' do
      n = Note.create!(author: top_leader, subject: top_leader, text: 'lorem')
      expect do
        post :destroy, group_id: n.subject.groups.first.id,
                       person_id: n.subject_id,
                       id: n.id,
                       format: :js
      end.to change { Note.count }.by(-1)
      is_expected.to render_template('destroy')
    end

    it 'redirects for html requests' do
      group = top_leader.groups.first
      n = Note.create!(author: top_leader, subject: top_leader, text: 'lorem')
      expect do
        post :destroy, group_id: group.id,
                       person_id: n.subject_id,
                       id: n.id
      end.to change { Note.count }.by(-1)
      is_expected.to redirect_to(group_person_path(group, top_leader))
    end
  end

end
