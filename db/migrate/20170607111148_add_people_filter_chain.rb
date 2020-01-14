# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddPeopleFilterChain < ActiveRecord::Migration[4.2]
  def change
    add_column :people_filters, :filter_chain, :text
    add_column :people_filters, :range, :string, default: 'deep'

    add_column :people_filters, :created_at, :timestamp
    add_column :people_filters, :updated_at, :timestamp

    PeopleFilter.reset_column_information

    PeopleFilter.find_each do |filter|
      types = RelatedRoleType.where(relation: filter).pluck(:role_type)
      filter.update!(range: 'deep', filter_chain: { role: { role_types: types } })
    end
  end
end
