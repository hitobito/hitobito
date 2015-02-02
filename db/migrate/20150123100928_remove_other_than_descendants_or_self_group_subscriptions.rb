class RemoveOtherThanDescendantsOrSelfGroupSubscriptions < ActiveRecord::Migration

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
