# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: mailing_lists
#
#  id                   :integer          not null, primary key
#  name                 :string           not null
#  group_id             :integer          not null
#  description          :text
#  publisher            :string
#  mail_name            :string
#  additional_sender    :string
#  subscribable         :boolean          default(FALSE), not null
#  subscribers_may_post :boolean          default(FALSE), not null
#  anyone_may_post      :boolean          default(FALSE), not null
#

class MailingList < ActiveRecord::Base

  belongs_to :group

  has_many :subscriptions, dependent: :destroy

  has_many :person_add_requests,
           foreign_key: :body_id,
           inverse_of: :body,
           class_name: 'Person::AddRequest::MailingList',
           dependent: :destroy

  validates_by_schema
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

  def people(people_scope = Person.only_public_data)
    people_scope_maybe_with_roles(people_scope).
      joins(people_joins).
      joins(subscription_joins).
      where(subscriptions: { mailing_list_id: id }).
      where("people.id NOT IN (#{excluded_person_subscribers.to_sql})").
      where(suscriber_conditions).
      uniq
  end

  private

  def people_scope_maybe_with_roles(people_scope)
    if self.class.connection.adapter_name.casecmp('mysql2') == 0
      people_scope.
        joins(combined_role_join).select('all_roles.role_with_layer')
    else
      people_scope
    end
  end

  # this is MySQL-specific SQL, namely GROUP_CONCAT(... SEPARATOR ...) and CONCAT_WS
  def combined_role_join
    <<-SQL.strip_heredoc.split.map(&:strip).join(' ')
      INNER JOIN (
        SELECT DISTINCT people.id, GROUP_CONCAT(CONCAT_WS(' / ', layers.name, groups.name) SEPARATOR ', ') AS role_with_layer
        FROM people
        LEFT JOIN roles ON people.id = roles.person_id
        LEFT JOIN groups ON roles.group_id = groups.id
        LEFT JOIN groups AS layers ON ( groups.layer_group_id = layers.id AND groups.id <> layers.id)
        GROUP BY people.id
      ) AS all_roles ON (people.id = all_roles.id)
    SQL
  end

  def people_joins
    <<-SQL.strip_heredoc.split.map(&:strip).join(' ')
      LEFT JOIN roles ON people.id = roles.person_id
      LEFT JOIN groups ON roles.group_id = groups.id
      LEFT JOIN event_participations ON event_participations.person_id = people.id
      LEFT JOIN taggings AS people_taggings
        ON people_taggings.taggable_type = 'Person'
        AND people_taggings.taggable_id = people.id
    SQL
  end

  def subscription_joins
    # the comma is needed because it is not a JOIN, but a second "FROM"
    <<-SQL.strip_heredoc.split.map(&:strip).join(' ')
      , subscriptions
      LEFT JOIN groups sub_groups
        ON subscriptions.subscriber_type = 'Group' AND subscriptions.subscriber_id = sub_groups.id
      LEFT JOIN related_role_types
        ON related_role_types.relation_type = 'Subscription' AND related_role_types.relation_id = subscriptions.id
      LEFT JOIN taggings AS subscriptions_taggings
        ON subscriptions_taggings.taggable_type = 'Subscription' AND subscriptions_taggings.taggable_id = subscriptions.id
    SQL
  end

  def suscriber_conditions
    condition = OrCondition.new
    person_subscribers(condition)
    event_subscribers(condition)
    group_subscribers(condition)
    condition.to_a
  end

  def person_subscribers(condition)
    condition.or('subscriptions.subscriber_type = ? AND ' \
                 'subscriptions.excluded = ? AND ' \
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
                 'subscriptions.subscriber_id = sub_groups.id AND ' \
                 'groups.lft >= sub_groups.lft AND groups.rgt <= sub_groups.rgt AND ' \
                 'roles.type = related_role_types.role_type AND ' \
                 'roles.deleted_at IS NULL AND ' \
                 '(subscriptions_taggings.tag_id IS NULL OR ' \
                 ' people_taggings.tag_id = subscriptions_taggings.tag_id)',
                 Group.sti_name)
  end

  def event_subscribers(condition)
    condition.or('subscriptions.subscriber_type = ? AND ' \
                 'subscriptions.subscriber_id = event_participations.event_id AND ' \
                 'event_participations.active = ?',
                 Event.sti_name,
                 true)
  end

  def assert_mail_name_is_not_protected
    if mail_name? && application_retriever_name
      if mail_name.casecmp(application_retriever_name.split('@', 2).first) == 0
        errors.add(:mail_name, :not_allowed, mail_name: mail_name)
      end
    end
  end

  def application_retriever_name
    config = Settings.email.retriever.config
    config.presence && config.user_name.presence
  end
end
