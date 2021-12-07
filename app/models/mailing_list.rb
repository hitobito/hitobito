# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: mailing_lists
#
#  id                                  :integer          not null, primary key
#  additional_sender                   :string(255)
#  anyone_may_post                     :boolean          default(FALSE), not null
#  delivery_report                     :boolean          default(FALSE), not null
#  description                         :text(16777215)
#  mail_name                           :string(255)
#  mailchimp_api_key                   :string(255)
#  mailchimp_include_additional_emails :boolean          default(FALSE)
#  mailchimp_last_synced_at            :datetime
#  mailchimp_result                    :text(16777215)
#  mailchimp_syncing                   :boolean          default(FALSE)
#  main_email                          :boolean          default(FALSE)
#  name                                :string(255)      not null
#  preferred_labels                    :string(255)
#  publisher                           :string(255)
#  subscribable                        :boolean          default(FALSE), not null
#  subscribers_may_post                :boolean          default(FALSE), not null
#  group_id                            :integer          not null
#  mailchimp_list_id                   :string(255)
#
# Indexes
#
#  index_mailing_lists_on_group_id  (group_id)
#

class MailingList < ActiveRecord::Base

  serialize :preferred_labels, Array
  attribute :mailchimp_result, Synchronize::Mailchimp::ResultType.new

  belongs_to :group

  has_many :subscriptions, dependent: :destroy

  has_many :person_add_requests,
           foreign_key: :body_id,
           inverse_of: :body,
           class_name: 'Person::AddRequest::MailingList',
           dependent: :destroy

  has_many :messages, dependent: :nullify

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

  scope :list, -> { order(:name) }
  scope :subscribable, -> { where(subscribable: true) }
  scope :mailchimp, -> do
    where.not(mailchimp_api_key: ['', nil]).where.not( mailchimp_list_id: ['', nil])
  end

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
    subscriptions
      .where(subscriber_id: person.id,
             subscriber_type: Person.sti_name,
             excluded: false)
      .destroy_all

    if subscribed?(person)
      sub = subscriptions.new
      sub.subscriber = person
      sub.excluded = true
      sub.save!
    end
  end

  def people(people_scope = Person.only_public_data)
    MailingLists::Subscribers.new(self, people_scope).people
  end

  def people_count(people_scope = Person)
    MailingLists::Subscribers.new(self, people_scope).people.count
  end

  def household_count(people_scope = Person)
    subscribers_scope = MailingLists::Subscribers.new(self, people_scope).people
    households = People::HouseholdList.new(subscribers_scope)

    # count total rows after grouping, instead of adding a count to each grouped row
    Person.from(households.grouped_households).count
  end

  def sync
    Synchronize::Mailchimp::Synchronizator.new(self).perform
  end

  def mailchimp_client
    Synchronize::Mailchimp::Client.new(self)
  end

  private

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

  def schedule_mailchimp_destroy
    MailchimpDestructionJob.new(mailchimp_list_id, mailchimp_api_key, people).enqueue!
  end
end
