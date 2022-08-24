#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe TableDisplaysController do

  let(:person) { people(:top_leader) }

  let!(:registered_columns) { TableDisplay.table_display_columns.clone }
  let!(:registered_multi_columns) { TableDisplay.multi_columns.clone }

  before do
    TableDisplay.table_display_columns = {}
    TableDisplay.multi_columns = {}
    TableDisplay.register_column(Person, TableDisplays::PublicColumn, 'names')
    sign_in(person)
  end

  after do
    TableDisplay.table_display_columns = registered_columns
    TableDisplay.multi_columns = registered_multi_columns
  end

  it 'POST#create persists selected columns to table_display' do
    post :create, params: { table_model_class: Person, selected: ['names'] }, format: :js
    expect(person.table_display_for(Person).selected).to eq %w(names)
  end

  it 'POST#create supports persisting empty selection' do
    post :create, params: { table_model_class: Person, }, format: :js
    expect(person.table_display_for(Person).selected).to be_empty
  end
end
