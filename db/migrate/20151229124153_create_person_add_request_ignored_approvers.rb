# encoding: utf-8

#  Copyright (c) 2017, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePersonAddRequestIgnoredApprovers < ActiveRecord::Migration[4.2]
  def change
    create_table :person_add_request_ignored_approvers do |t|
      t.belongs_to :group, null: false
      t.belongs_to :person, null: false
    end

    add_index :person_add_request_ignored_approvers,
              [:group_id, :person_id],
              name: 'person_add_request_ignored_approvers_index',
              unique: true
  end
end
