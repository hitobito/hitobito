class AddMailchimpIncludeNamesToMailingList < ActiveRecord::Migration[6.0]
  def change
    add_column :mailing_lists, :mailchimp_include_names, :boolean, default: false
  end
end
