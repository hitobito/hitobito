# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

class MailingList < ActiveRecord::Base

  belongs_to :group

  has_many :subscriptions, dependent: :destroy


  validates :mail_name, uniqueness: { case_sensitive: false },
                        format: /\A[a-z][a-z0-9\-\_\.]*\Z/,
                        allow_blank: true
  validates :description, length: { allow_nil: true, maximum: 2**16 - 1 }
  validate :assert_mail_name_is_not_protected


  def to_s(_format = :default)
    name
  end

  def mail_address
    "#{mail_name}@#{mail_domain}" if mail_name?
  end

  def mail_domain
    Settings.email.list_domain
  end

  def subscribed?(person)
    people.where(id: person.id).exists?
  end

  def exclude_person(person)
    subscriptions.where(subscriber_id: person.id,
                        subscriber_type: Person.sti_name,
                        excluded: false).
                  destroy_all

    if subscribed?(person)
      sub = subscriptions.new
      sub.subscriber = person
      sub.excluded = true
      sub.save!
    end
  end

  # rubocop:disable MethodLength
  def people(people_scope = Person.only_public_data)
    people_scope.
           joins('LEFT JOIN roles ON people.id = roles.person_id').
           joins('LEFT JOIN groups ON roles.group_id = groups.id').
           joins('LEFT JOIN event_participations ON event_participations.person_id = people.id').
           joins(', subscriptions ').
           joins('LEFT JOIN groups sub_groups ' \
                 "ON subscriptions.subscriber_type = 'Group'" <<
                 'AND subscriptions.subscriber_id = sub_groups.id ').
           joins('LEFT JOIN related_role_types ' \
                 "ON related_role_types.relation_type = 'Subscription' " <<
                 'AND related_role_types.relation_id = subscriptions.id').
           where(subscriptions: { mailing_list_id: id }).
           where("people.id NOT IN (#{excluded_person_subscribers.to_sql})").
           where(suscriber_conditions).
           uniq
  end
  # rubocop:enable MethodLength

  private

  def suscriber_conditions
    condition = OrCondition.new
    person_subscribers(condition)
    event_subscribers(condition)
    group_subscribers(condition)
    condition.to_a
  end

  def person_subscribers(condition)
    condition.or('subscriptions.subscriber_type = ? AND ' \
                 'subscriptions.excluded = ? AND ' <<
                 'subscriptions.subscriber_id = people.id',
                 Person.sti_name,
                 false)
  end

  def excluded_person_subscribers
    Subscription.select(:subscriber_id).
                 where(mailing_list_id: id,
                       excluded: true,
                       subscriber_type: Person.sti_name)
  end

  def group_subscribers(condition)
    condition.or('subscriptions.subscriber_type = ? AND ' \
                 'subscriptions.subscriber_id = sub_groups.id AND ' <<
                 'groups.lft >= sub_groups.lft AND groups.rgt <= sub_groups.rgt AND ' \
                 'roles.type = related_role_types.role_type AND ' \
                 'roles.deleted_at IS NULL',
                 Group.sti_name)
  end

  def event_subscribers(condition)
    condition.or('subscriptions.subscriber_type = ? AND ' \
                 'subscriptions.subscriber_id = event_participations.event_id AND ' <<
                 'event_participations.active = ?',
                 Event.sti_name,
                 true)
  end

  def assert_mail_name_is_not_protected
    if mail_name? && application_retriever_name
      if mail_name.downcase == application_retriever_name.split('@', 2).first.downcase
        errors.add(:mail_name, :not_allowed, mail_name: mail_name)
      end
    end
  end

  def application_retriever_name
    Settings.email.retriever.config.user_name.presence
  end
end
