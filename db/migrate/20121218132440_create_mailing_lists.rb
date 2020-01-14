# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateMailingLists < ActiveRecord::Migration[4.2]
  def change
    create_table :mailing_lists do |t|
      t.string :name, null: false
      t.belongs_to :group, null: false
      t.text :description
      t.string :publisher
      t.string :mail_name
      t.string :additional_sender
      t.boolean :subscribable, default: false, null: false
      t.boolean :subscribers_may_post, default: false, null: false
    end

    create_table :subscriptions do |t|
      t.belongs_to :mailing_list, null: false
      t.belongs_to :subscriber, null: false, polymorphic: true
      t.boolean :excluded, default: false, null: false
    end

    rename_table :people_filter_role_types, :related_role_types

    rename_column :related_role_types, :people_filter_id, :relation_id
    add_column :related_role_types, :relation_type, :string

    RelatedRoleType.update_all(relation_type: 'PeopleFilter')
  end
end
