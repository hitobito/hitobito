#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe TableDisplaysController do

  let(:person) { people(:top_leader) }
  let(:group)  { groups(:top_group) }

  before { sign_in(person) }

  it 'POST#create persists selected columns to table_display' do
    post :create, params: { parent_id: group.id, parent_type: 'Group', selected: ['names'] }, format: :js
    expect(person.table_display_for(group).selected).to eq %w(names)
  end

  it 'POST#create supports persisting empty selection' do
    post :create, params: { parent_id: group.id, parent_type: 'Group' }, format: :js
    expect(person.table_display_for(group).selected).to be_empty
  end
end
