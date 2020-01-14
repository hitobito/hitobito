class AddDeliveryReportsToMailingLists < ActiveRecord::Migration[4.2]
  def change
    add_column(:mailing_lists, :delivery_report, :boolean, default: false, null: false)
  end
end
