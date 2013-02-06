# == Schema Information
#
# Table name: subscriptions
#
#  id              :integer          not null, primary key
#  mailing_list_id :integer          not null
#  subscriber_id   :integer          not null
#  subscriber_type :string(255)      not null
#  excluded        :boolean          default(FALSE), not null
#

Fabricator(:subscription) do
  subscriber { Fabricate(:person) }
end
