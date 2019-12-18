# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: mailing_lists
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  group_id                 :integer          not null
#  description              :text(65535)
#  publisher                :string(255)
#  mail_name                :string(255)
#  additional_sender        :string(255)
#  subscribable             :boolean          default(FALSE), not null
#  subscribers_may_post     :boolean          default(FALSE), not null
#  anyone_may_post          :boolean          default(FALSE), not null
#  preferred_labels         :string(255)
#  delivery_report          :boolean          default(FALSE), not null
#  main_email               :boolean          default(FALSE)
#  mailchimp_api_key        :string(255)
#  mailchimp_list_id        :string(255)
#  mailchimp_syncing        :boolean          default(FALSE)
#  mailchimp_last_synced_at :datetime
#

class MailingList < ActiveRecord::Base

  serialize :preferred_labels, Array

  belongs_to :group

  has_many :subscriptions, dependent: :destroy

  has_many :person_add_requests,
           foreign_key: :body_id,
           inverse_of: :body,
           class_name: 'Person::AddRequest::MailingList',
           dependent: :destroy

  has_many :mail_logs, dependent: :nullify

  validates_by_schema
  validates :mail_name, uniqueness: { case_sensitive: false },
                        format: /\A[a-z][a-z0-9\-\_\.]*\Z/,
                        allow_blank: true
  validates :description, length: { allow_nil: true, maximum: 2**16 - 1 }
  validate :assert_mail_name_is_not_protected
  validates :additional_sender,
      allow_blank: true,
      format: /\A *(([a-z][a-z0-9\-\_\.]*|\*)@([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,} *(,|;|\Z) *)+\Z/

  after_destroy :schedule_mailchimp_destroy, if: :mailchimp?

  DEFAULT_LABEL = '_main'.freeze

  def to_s(_format = :default)
    name
  end

  def labels
    main_email ? preferred_labels + [DEFAULT_LABEL] : preferred_labels
  end

  def mailchimp?
    [mailchimp_api_key, mailchimp_list_id].all?(&:present?)
  end

  def preferred_labels=(labels)
    self[:preferred_labels] = labels.reject(&:blank?).collect(&:strip).uniq.sort
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
    people_scope.
      joins(people_joins).
      joins(subscription_joins).
      where(subscriptions: { mailing_list_id: id }).
      where("people.id NOT IN (#{excluded_person_subscribers.to_sql})").
      where(suscriber_conditions).
      distinct
  end

  private

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
      if mail_name.casecmp(application_retriever_name.split('@', 2).first).zero?
        errors.add(:mail_name, :not_allowed, mail_name: mail_name)
      end
    end
  end

  def application_retriever_name
    config = Settings.email.retriever.config
    config.presence && config.user_name.presence
  end

  private

  def schedule_mailchimp_destroy
    MailchimpDestructionJob.new(mailchimp_list_id, mailchimp_api_key, people).enqueue!
  end

end
