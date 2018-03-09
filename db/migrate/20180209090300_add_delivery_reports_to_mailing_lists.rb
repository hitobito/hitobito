class AddDeliveryReportsToMailingLists < ActiveRecord::Migration
  def change
    add_column(:mailing_lists, :delivery_report, :boolean, default: false, null: false)
  end
end
