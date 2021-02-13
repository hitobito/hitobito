#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: subscriptions
#
#  id              :integer          not null, primary key
#  excluded        :boolean          default(FALSE), not null
#  subscriber_type :string(255)      not null
#  mailing_list_id :integer          not null
#  subscriber_id   :integer          not null
#
# Indexes
#
#  index_subscriptions_on_mailing_list_id                    (mailing_list_id)
#  index_subscriptions_on_subscriber_id_and_subscriber_type  (subscriber_id,subscriber_type)
#

Fabricator(:subscription) do
  subscriber { Fabricate(:person) }
end
