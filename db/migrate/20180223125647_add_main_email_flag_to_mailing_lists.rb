class AddMainEmailFlagToMailingLists < ActiveRecord::Migration
  def change
    add_column(:mailing_lists, :main_email, :boolean, default: false)
  end
end
