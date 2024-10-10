#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people_filters
#
#  id           :integer          not null, primary key
#  filter_chain :text
#  group_type   :string
#  name         :string           not null
#  range        :string           default("deep")
#  created_at   :datetime
#  updated_at   :datetime
#  group_id     :integer
#
# Indexes
#
#  index_people_filters_on_group_id_and_group_type  (group_id,group_type)
#

require "spec_helper"

describe PeopleFilter do
  context "#filter_chain=" do
    it "assigns hash to filter_chain" do
      filter = PeopleFilter.new(filter_chain: {role: {role_type_ids: [2, 3, 4]}})
      expect(filter.filter_chain[:role].to_params).to eq(role_type_ids: "2-3-4")
    end
  end
end
