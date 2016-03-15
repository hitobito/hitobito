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

  describe 'POST #create' do

    it 'creates person notes' do
      post :create, group_id: bottom_member.groups.first.id, person_id: bottom_member.id,
                    note: { text: 'Lorem ipsum' }

      is_expected.to redirect_to new_person_session_path
      expect(Person::Note.count).to eq(1)

    end

  end

end
