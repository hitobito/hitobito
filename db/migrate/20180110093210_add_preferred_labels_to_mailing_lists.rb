class AddPreferredLabelsToMailingLists < ActiveRecord::Migration[4.2]
  def change
    add_column(:mailing_lists, :preferred_labels, :string)
  end
end
