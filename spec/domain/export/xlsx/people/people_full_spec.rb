#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::PeopleFull do
  let(:person) { people(:top_leader) }
  let(:scope) { Person.where(id: person.id) }

  it "exports people scope full as xlsx" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .twice.and_call_original

    Export::Tabular::People::PeopleFull.xlsx(scope)
  end
end
