require 'spec_helper'

describe TableDisplaysController do

  let(:person) { people(:top_leader) }
  let(:group)  { groups(:top_group) }

  before { sign_in(person) }

  it 'POST#create persists selected columns to table_display' do
    post :create, parent_id: group.id, parent_type: 'Group', selected: ['names'], format: :js
    expect(person.table_display_for(group).selected).to eq %w(names)
  end

  it 'POST#create supports persisting empty selection' do
    post :create, parent_id: group.id, parent_type: 'Group', format: :js
    expect(person.table_display_for(group).selected).to be_empty
  end
end
