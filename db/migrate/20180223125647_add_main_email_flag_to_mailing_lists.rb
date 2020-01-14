class AddMainEmailFlagToMailingLists < ActiveRecord::Migration[4.2]
  def change
    add_column(:mailing_lists, :main_email, :boolean, default: false)
  end
end
