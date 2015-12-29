class CreatePersonAddRequestIgnoredApprovers < ActiveRecord::Migration
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
