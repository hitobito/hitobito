# frozen_string_literal: true

#  Copyright (c) 2023, CEVI Schweiz, Pfadibewegung Schweiz,
#  Jungwacht Blauring Schweiz, Pro Natura, Stiftung für junge Auslandschweizer.
#  This file is part of hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe "people merge", :js do
  let(:user) { top_leader }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:person_1) { Fabricate("Group::BottomLayer::Member", group: groups(:bottom_layer_one)).person }
  let(:person_2) { Fabricate("Group::BottomLayer::Member", group: groups(:bottom_layer_one)).person }
  let!(:duplicate_entry) { PersonDuplicate.create!(person_1: person_1, person_2: person_2) }

  before { sign_in(user) }

  it "merges managers" do
    person_1.managers = [top_leader]
    person_1.save
    person_2.managers = [bottom_member]
    person_2.save

    visit group_person_duplicates_path(groups(:bottom_layer_one))

    find_all(".person-duplicates-table td.vertical-middle a").first.click

    find("form .modal-footer button").click

    expect(page).to have_content("Die Personen Einträge wurden erfolgreich zusammengeführt.")

    expect(PersonDuplicate.where(id: duplicate_entry.id)).to_not exist
    expect(Person.where(id: person_2.id)).to_not exist
    expect(person_1.managers.reload).to match_array([top_leader, bottom_member])
  end

  it "merges manageds" do
    person_1.manageds = [top_leader]
    person_1.save
    person_2.manageds = [bottom_member]
    person_2.save

    visit group_person_duplicates_path(groups(:bottom_layer_one))

    find_all(".person-duplicates-table td.vertical-middle a").first.click

    find("form .modal-footer button").click

    expect(page).to have_content("Die Personen Einträge wurden erfolgreich zusammengeführt.")

    expect(PersonDuplicate.where(id: duplicate_entry.id)).to_not exist
    expect(Person.where(id: person_2.id)).to_not exist
    expect(person_1.manageds.reload).to match_array([top_leader, bottom_member])
  end

  it "prioritizes target manageds when merging both managers and manageds" do
    person_1.manageds = [top_leader]
    person_1.save
    person_2.managers = [bottom_member]
    person_2.save

    visit group_person_duplicates_path(groups(:bottom_layer_one))

    find_all(".person-duplicates-table td.vertical-middle a").first.click

    find("form .modal-footer button").click

    expect(page).to have_content("Die Personen Einträge wurden erfolgreich zusammengeführt.")

    expect(PersonDuplicate.where(id: duplicate_entry.id)).to_not exist
    expect(Person.where(id: person_2.id)).to_not exist
    expect(person_1.manageds.reload).to match_array([top_leader])
  end

  it "prioritizes target managers when merging both managers and manageds" do
    person_1.managers = [top_leader]
    person_1.save
    person_2.manageds = [bottom_member]
    person_2.save

    visit group_person_duplicates_path(groups(:bottom_layer_one))

    find_all(".person-duplicates-table td.vertical-middle a").first.click

    find("form .modal-footer button").click

    expect(page).to have_content("Die Personen Einträge wurden erfolgreich zusammengeführt.")

    expect(PersonDuplicate.where(id: duplicate_entry.id)).to_not exist
    expect(Person.where(id: person_2.id)).to_not exist
    expect(person_1.managers.reload).to match_array([top_leader])
  end
end
