
# frozen_string_literal: true

module Subscriptions::SpecHelper

  def create_event_subscription(mailing_list: list, groups: [group], participant: person)
    event = Fabricate(:event, groups: groups)
    event.participations.create!(person: person, active: true)
    event.reload.dates.first.update!(start_at: 10.days.ago)
    mailing_list.subscriptions.create!(subscriber: event)
  end

  def create_group_subscription(mailing_list: list, subscriber: group, excluded: false, role_types: %w(Group::TopGroup::Leader))
    create_subscription(mailing_list: mailing_list, subscriber: subscriber, excluded: excluded, role_types: role_types)
  end

  def create_person_subscription(mailing_list: list, subscriber: person, excluded: false)
    create_subscription(mailing_list: mailing_list, subscriber: subscriber, excluded: excluded)
  end

  private

  def create_subscription(mailing_list: list, subscriber: person, excluded: false, role_types: [])
    sub = mailing_list.subscriptions.new
    sub.subscriber = subscriber
    sub.excluded = excluded
    sub.related_role_types = role_types.collect { |t| RelatedRoleType.new(role_type: t) }
    sub.save!
    sub
  end
end

