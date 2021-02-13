
#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# == Schema Information
#
# Table name: addresses
#
#  id               :bigint           not null, primary key
#  subscription_id  :integer      not null
#  tag_id           :integer      not null
#  excluded         :boolean      not null
#

class SubscriptionTag < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :tag, class_name: "ActsAsTaggableOn::Tag"

  scope :excluded, -> { where(excluded: true) }
  scope :included, -> { where(excluded: false) }
end
