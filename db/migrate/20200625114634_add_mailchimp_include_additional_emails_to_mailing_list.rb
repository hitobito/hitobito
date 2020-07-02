class AddMailchimpIncludeAdditionalEmailsToMailingList < ActiveRecord::Migration[6.0]
  def change
    add_column :mailing_lists, :mailchimp_include_additional_emails, :boolean, default: false
  end
end
