class AddMailchimpResultToMailingLists < ActiveRecord::Migration[6.0]
  def change
    add_column(:mailing_lists, :mailchimp_result, :text)
  end
end
