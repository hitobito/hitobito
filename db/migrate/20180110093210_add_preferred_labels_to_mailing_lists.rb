class AddPreferredLabelsToMailingLists < ActiveRecord::Migration
  def change
    add_column(:mailing_lists, :preferred_labels, :string)
  end
end
