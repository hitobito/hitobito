json_contact_accounts(json, contactable.additional_emails, only_public) do |email|
  json.extract!(email, :mailings)
end

json_contact_accounts(json, contactable.phone_numbers, only_public)

json_contact_accounts(json, contactable.social_accounts, only_public)

