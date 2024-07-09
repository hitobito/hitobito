#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: subscription_tags
#
#  id              :bigint           not null, primary key
#  excluded        :boolean          default(FALSE)
#  subscription_id :integer          not null
#  tag_id          :integer          not null
#
# Indexes
#
#  index_subscription_tags_on_subscription_id  (subscription_id)
#  index_subscription_tags_on_tag_id           (tag_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id)
#  fk_rails_...  (tag_id => tags.id)
#

class SubscriptionTag < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :tag, class_name: "ActsAsTaggableOn::Tag"

  scope :excluded, -> { where(excluded: true) }
  scope :included, -> { where(excluded: false) }
end
