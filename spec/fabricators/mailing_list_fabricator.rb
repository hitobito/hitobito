# == Schema Information
#
# Table name: mailing_lists
#
#  id                   :integer          not null, primary key
#  name                 :string(255)      not null
#  group_id             :integer          not null
#  description          :text
#  publisher            :string(255)
#  mail_name            :string(255)
#  additional_sender    :string(255)
#  subscribable         :boolean          default(FALSE), not null
#  subscribers_may_post :boolean          default(FALSE), not null
#

Fabricator(:mailing_list) do
  name { Faker::Company.name }
end
