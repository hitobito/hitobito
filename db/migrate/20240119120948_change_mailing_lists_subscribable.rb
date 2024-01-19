class ChangeMailingListsSubscribable < ActiveRecord::Migration[6.1]
  def change
    Person.transaction do
      add_column(:mailing_lists, :subscribable_by, :string, default: :none, null: false)
      add_column(:mailing_lists, :subscribable_subscribed, :string, default: :subscribed, null: false)
      reversible do |dir|
        dir.up do
          execute "UPDATE mailing_lists SET subscribable_by = 'all' WHERE subscribable = true"
        end
        dir.down do
          execute "UPDATE mailing_lists SET subscribable = true WHERE subscribable_by = 'all'"
        end
      end
      # remove_column(:mailing_lists, :subscribable, :boolean, default: :false)
    end
  end
end
