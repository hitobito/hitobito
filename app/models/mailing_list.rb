#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: mailing_lists
#
#  id                                  :integer          not null, primary key
#  additional_sender                   :string
#  anyone_may_post                     :boolean          default(FALSE), not null
#  delivery_report                     :boolean          default(FALSE), not null
#  description                         :text
#  filter_chain                        :text
#  mail_name                           :string
#  mailchimp_api_key                   :string
#  mailchimp_forgotten_emails          :text
#  mailchimp_include_additional_emails :boolean          default(FALSE)
#  mailchimp_last_synced_at            :datetime
#  mailchimp_result                    :text
#  mailchimp_syncing                   :boolean          default(FALSE)
#  main_email                          :boolean          default(FALSE)
#  name                                :string           not null
#  preferred_labels                    :string
#  publisher                           :string
#  subscribable_for                    :string           default("nobody"), not null
#  subscribable_mode                   :string
#  subscribers_may_post                :boolean          default(FALSE), not null
#  group_id                            :integer          not null
#  mailchimp_list_id                   :string
#
# Indexes
#
#  index_mailing_lists_on_group_id  (group_id)
#

class MailingList < ActiveRecord::Base
  include I18nEnums

  SUBSCRIBABLE_FORS = %w[nobody configured anyone].freeze
  SUBSCRIBABLE_MODES = %w[opt_out opt_in].freeze

  serialize :preferred_labels, type: Array, coder: NilArrayCoder
  serialize :filter_chain, type: MailingLists::Filter::Chain, coder: MailingLists::Filter::Chain

  serialize :mailchimp_forgotten_emails, type: Array, coder: NilArrayCoder
  attribute :mailchimp_result, Synchronize::Mailchimp::ResultType.new

  belongs_to :group

  has_many :subscriptions, dependent: :destroy

  has_many :person_add_requests,
    foreign_key: :body_id,
    inverse_of: :body,
    class_name: "Person::AddRequest::MailingList",
    dependent: :destroy

  has_many :messages, dependent: :nullify

  validates_by_schema
  before_validation :set_default_subscribable_mode

  validates :mail_name, uniqueness: {case_sensitive: false},
    format: /\A[a-z][a-z0-9\-\_\.]*\Z/,
    allow_blank: true
  validates :description, length: {allow_nil: true, maximum: (2**16) - 1}
  validate :assert_mail_name_is_not_protected
  validates :additional_sender,
    allow_blank: true,
    format: /\A *(([a-z][a-z0-9\-\_\.]*|\*)@([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,} *(,|;|\Z) *)+\Z/

  validates :subscribable_for, inclusion: {in: SUBSCRIBABLE_FORS}
  validates :subscribable_mode, inclusion: {in: SUBSCRIBABLE_MODES}, if: :subscribable?

  after_destroy :schedule_mailchimp_destroy, if: :mailchimp?
  after_save :schedule_opt_in_cleanup, if: :opt_in?

  scope :list, -> { order(:name) }
  scope :anyone, -> { where(subscribable_for: :anyone) }
  scope :configured, -> { where(subscribable_for: :configured) }
  scope :opt_in, -> { where(subscribable_for: :configured, subscribable_mode: :opt_in) }
  scope :opt_out, -> { where(subscribable_for: :configured, subscribable_mode: :opt_out) }
  scope :subscribable, -> { where(subscribable_for: [:anyone, :configured]) }
  scope :with_filter_chain, -> { where.not(filter_chain: MailingLists::Filter::Chain.new({})) }
  scope :mailchimp, -> do
    where.not(mailchimp_api_key: ["", nil]).where.not(mailchimp_list_id: ["", nil])
  end

  DEFAULT_LABEL = "_main".freeze

  i18n_enum :subscribable_for, SUBSCRIBABLE_FORS, scopes: true
  i18n_enum :subscribable_mode, SUBSCRIBABLE_MODES, scopes: true

  def to_s(_format = :default)
    name
  end

  def opt_in?
    subscribable_mode == "opt_in"
  end

  def subscribable?
    (SUBSCRIBABLE_FORS - %w[nobody]).include?(subscribable_for)
  end

  def subscribable_for_configured?
    subscribable_for.to_s == "configured"
  end

  def labels
    main_email ? preferred_labels + [DEFAULT_LABEL] : preferred_labels
  end

  def mailchimp?
    [mailchimp_api_key, mailchimp_list_id].all?(&:present?)
  end

  def preferred_labels=(labels)
    self[:preferred_labels] = labels.compact_blank.collect(&:strip).uniq.sort
  end

  def mail_address
    "#{mail_name}@#{mail_domain}" if mail_name?
  end

  def mail_domain
    Settings.email.list_domain
  end

  def exclude_person(person)
    Person::Subscriptions.new(person).unsubscribe(self)
  end

  def subscribed?(person, time: Time.zone.now)
    MailingLists::Subscribers.new(self, time:).subscribed?(person)
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
    households.count
  end

  def sync
    Synchronize::Mailchimp::Synchronizator.new(self).perform
  end

  def mailchimp_client
    Synchronize::Mailchimp::Client.new(self)
  end

  def path_args
    [group, self]
  end

  def filter_chain=(value)
    if value.is_a?(Hash)
      super(MailingLists::Filter::Chain.new(value))
    else
      super
    end
  end

  def schedule_opt_in_cleanup
    return unless subscribable_mode_previously_was == "opt_out"

    Subscriptions::OptInCleanupJob.new(id).enqueue!
  end

  private

  def set_default_subscribable_mode
    if subscribable? && subscribable_mode.blank?
      self.subscribable_mode = "opt_out"
    elsif !subscribable?
      self.subscribable_mode = nil
    end
  end

  def assert_mail_name_is_not_protected
    if mail_name? && application_retriever_name
      if mail_name.casecmp(application_retriever_name.split("@", 2).first).zero?
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
