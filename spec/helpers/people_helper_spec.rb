#  Copyright (c) 2014, SAC-CAS. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeopleHelper do
  describe "#oneline_address" do
    it "formats the address" do
      @person = people(:top_leader)
      message = messages(:simple)
      expect(oneline_address(message)).to eq("Hauptstrasse 1, 3023 Musterstadt")
    end
  end
end
