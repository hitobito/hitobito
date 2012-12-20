class CreateMailingLists < ActiveRecord::Migration
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
