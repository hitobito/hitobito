# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class RemoveAddressFromPeopleAndGroups < ActiveRecord::Migration[6.1]
  def change
    if Group.any? && (unmigrated(Person).any? || unmigrated(Group).any?)
      raise "Not all addresses have been migrated into structured form or handled."
    end

    remove_column :people, :search_column, if_exists: true
    remove_column :groups, :search_column, if_exists: true
    remove_column :people, :address, :text, limit: 1024
    remove_column :groups, :address, :text, limit: 1024
    Group.reset_column_information
    Person.reset_column_information
  end

  private

  def unmigrated(model) = model.where.not(address: nil).where.not(address: "")
end
