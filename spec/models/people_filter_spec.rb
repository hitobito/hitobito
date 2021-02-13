# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people_filters
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  group_id   :integer
#  group_type :string
#

require "spec_helper"

describe PeopleFilter do

  context "#filter_chain=" do

    it "assigns hash to filter_chain" do
      filter = PeopleFilter.new(filter_chain: { role: { role_type_ids: [1, 2, 3] }})
      expect(filter.filter_chain[:role].to_params).to eq(role_type_ids: "1-2-3")
    end

  end

end
