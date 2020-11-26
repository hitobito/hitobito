# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe :person_duplicates, js: true do

  subject { page }

  let(:top_layer) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }
  let!(:duplicate1) { Fabricate(:person_duplicate) }
  let!(:duplicate2) { Fabricate(:person_duplicate) }
  let!(:duplicate3) { Fabricate(:person_duplicate) }


  before do
    assign_people
    sign_in
    visit group_person_duplicates_path(top_layer)
  end

  it 'lists duplicates and acknowledges or merges them' do
    person_rows = find('#content table.table tbody').all('tr:not(.divider)')

    expect(person_rows.count).to eq(6)

    d1_merge_link = new_merge_group_person_duplicate_path(top_layer, duplicate1)
    page.find('#content table.table a[href="' + d1_merge_link + '"]').click

    modal = page.find('div.modal-dialog')
    expect(modal.find('h5')).to have_content 'Personen zusammenführen'
    
    expect do
      modal.find('button.btn', text: 'Zusammenführen').click
    end.to change(Person, :count).by(-1)

    expect(Person.where(id: duplicate1.id)).not_to exist
  end

  private

  def assign_people
    [duplicate1, duplicate2, duplicate3].each do |d|
      Fabricate('Group::TopLayer::TopAdmin', group: top_layer, person: d.person_1)
      Fabricate('Group::TopLayer::TopAdmin', group: top_layer, person: d.person_2)
    end
  end

end
