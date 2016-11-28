# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::DeletedPeopleController do

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader)  }

  context 'authenticated' do

    before { sign_in(person) }

    it 'render index view' do
      get :index, group_id: group.id
      is_expected.to render_template('group/deleted_people/index')
    end
    
  end
end
