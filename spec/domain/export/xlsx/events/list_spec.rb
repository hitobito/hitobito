# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Events::List do

  let(:courses) { [course1] }
  let(:course1) { events(:top_course) }

  it "exports events list as xlsx" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(2).times.and_call_original

    Export::Tabular::Events::List.xlsx(courses)
  end

end
