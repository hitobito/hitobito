# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEventsGroupsAndSomeFields < ActiveRecord::Migration[4.2]
  def up
    create_table :events_groups, id: false do |t|
      t.belongs_to :event
      t.belongs_to :group
    end

    # this breaks applying migrations when
    # creating new tenants on instances with appartment.
    # since this is a pretty old migration, it's save to just
    # comment these lines
    # Event.find_each do |e|
      # e.group_ids = [e.group_id]
      # e.save!
    # end

    remove_column :events, :group_id

    add_column :events, :application_contact_id, :integer

    add_column :qualifications, :origin, :string

    add_column :people, :picture, :string
  end

  def down
    remove_column :people, :picture
    remove_column :qualifications, :origin
    remove_column :events, :application_contact_id

    add_column :events, :group_id, :integer
    Event.find_each do |e|
      e.group_id = e.group_ids.first
      e.save!
    end
    drop_table :events_groups
  end
end
