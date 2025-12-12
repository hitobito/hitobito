#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require "spec_helper"

describe PeopleFilter do
  context "#filter_chain=" do
    it "assigns hash to filter_chain" do
      filter = PeopleFilter.new(filter_chain: {role: {role_type_ids: [2, 3, 4]}})
      expect(filter.filter_chain.to_params["role"]).to eq(role_type_ids: "2-3-4")
    end
  end
end
