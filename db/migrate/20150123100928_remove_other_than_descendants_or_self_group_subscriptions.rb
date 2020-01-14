# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveOtherThanDescendantsOrSelfGroupSubscriptions < ActiveRecord::Migration[4.2]

  def up
    return if Wagons.find('jubla')

    subscriptions.find_each do |subscription|
      if invalid?(subscription)
        say "destroying subscription: #{subscription.inspect}"
        subscription.destroy!
      end
    end
  end

  def down
  end

  private

  def subscriptions
    Subscription.where(subscriber_type: 'Group').includes(:mailing_list)
  end

  def invalid?(subscription)
    subscriber_id = subscription.subscriber_id
    group = subscription.mailing_list.group
    valid_group_subscriber_ids = group.self_and_descendants.map(&:id)

    !valid_group_subscriber_ids.include?(subscriber_id)
  end
end
