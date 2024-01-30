# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriptions::SpecHelper

  def create_group_subscription(subscriber: group, mailing_list: list, excluded: false, role_types: %w(Group::TopGroup::Leader), included_tags: [], excluded_tags: [])
    create_subscription(subscriber, excluded, *role_types, mailing_list: mailing_list, included_tags: included_tags, excluded_tags: excluded_tags)
  end

  def create_person_subscription(mailing_list: list, excluded: false)
    create_subscription(person, excluded, mailing_list: mailing_list)
  end

  def create_event_subscription(mailing_list: list, groups: [group], included_tags: [], excluded_tags: [])
    event = Fabricate(:event, groups: groups)
    event.participations.create!(person: person, active: true)
    event.reload.dates.first.update!(start_at: 10.days.ago)
    mailing_list.subscriptions.create!(subscriber: event, subscription_tags: subscription_tags(included: included_tags, excluded: excluded_tags))
  end

  def create_subscription(subscriber, excluded = false, *role_types, mailing_list: list, included_tags: [], excluded_tags: [])
    sub = mailing_list.subscriptions.new
    sub.subscriber = subscriber
    sub.excluded = excluded
    sub.related_role_types = role_types.collect { |t| RelatedRoleType.new(role_type: t) }
    sub.subscription_tags = subscription_tags(included: included_tags, excluded: excluded_tags)
    sub.save!
    sub
  end

  def subscription_tags(included: [], excluded: [])
    included_tags = included.map do |name|
      SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create_or_find_by!(name: name))
    end
    excluded_tags = excluded.map do |name|
      SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create_or_find_by!(name: name), excluded: true)
    end
    included_tags + excluded_tags
  end

end

