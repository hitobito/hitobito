# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::PeopleFull do
  before do
    PeopleRelation.kind_opposites["parent"] = "child"
    PeopleRelation.kind_opposites["child"] = "parent"
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

  let(:person) { people(:top_leader) }
  let(:list) { [person] }

  it "exports people list full as xlsx" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(2).times.and_call_original

    Export::Tabular::People::PeopleFull.xlsx(list)
  end
end
