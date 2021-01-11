# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  applicant_count             :integer          default(0)
#  application_closing_at      :date
#  application_conditions      :text(16777215)
#  application_opening_at      :date
#  applications_cancelable     :boolean          default(FALSE), not null
#  cost                        :string(255)
#  description                 :text(16777215)
#  display_booking_info        :boolean          default(TRUE), not null
#  external_applications       :boolean          default(FALSE)
#  hidden_contact_attrs        :text(16777215)
#  location                    :text(16777215)
#  maximum_participants        :integer
#  motto                       :string(255)
#  name                        :string(255)      not null
#  number                      :string(255)
#  participant_count           :integer          default(0)
#  participations_visible      :boolean          default(FALSE), not null
#  priorization                :boolean          default(FALSE), not null
#  required_contact_attrs      :text(16777215)
#  requires_approval           :boolean          default(FALSE), not null
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string(255)
#  state                       :string(60)
#  teamer_count                :integer          default(0)
#  type                        :string(255)
#  waiting_list                :boolean          default(TRUE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  application_contact_id      :integer
#  contact_id                  :integer
#  creator_id                  :integer
#  kind_id                     :integer
#  updater_id                  :integer
#
# Indexes
#
#  index_events_on_kind_id  (kind_id)
#

# An event is any single or multi-day event that has participants and a
# leader-team. This could be anything from an internal team-meeting to a
# externally available information event for interested people.
#
# The same event may be attached to multiple groups of the same kind.
class Event < ActiveRecord::Base # rubocop:disable Metrics/ClassLength:

  # This statement is required because these classes would not be loaded correctly otherwise.
  # The price we pay for using classes as namespace.
  require_dependency 'event/date'
  require_dependency 'event/role'
  require_dependency 'event/restricted_role'
  require_dependency 'event/application_decorator'
  require_dependency 'event/role_decorator'
  require_dependency 'event/role_ability'

  include Event::Participatable

  ### ATTRIBUTES

  class_attribute :used_attributes,
                  :role_types,
                  :supports_applications,
                  :possible_states,
                  :kind_class

  # All attributes actually used (and mass-assignable) by the respective STI type.
  self.used_attributes = [:name, :motto, :cost, :maximum_participants, :contact_id,
                          :description, :location, :application_opening_at,
                          :application_closing_at, :application_conditions,
                          :external_applications, :applications_cancelable,
                          :signature, :signature_confirmation, :signature_confirmation_text,
                          :required_contact_attrs, :hidden_contact_attrs,
                          :participations_visible]

  # All participation roles that exist for this event
  self.role_types = [Event::Role::Leader,
                     Event::Role::AssistantLeader,
                     Event::Role::Cook,
                     Event::Role::Helper,
                     Event::Role::Treasurer,
                     Event::Role::Speaker,
                     Event::Role::Participant]

  # Are Event::Applications possible for this event type
  self.supports_applications = false

  # List of possible values for the state attribute.
  self.possible_states = []

  # The class used for the kind_id
  self.kind_class = nil


  model_stamper
  stampable stamper_class_name: :person,
            deleter: false

  ### ASSOCIATIONS

  # Autosave would change updated_at and updater on the group when creating an event.
  has_and_belongs_to_many :groups, autosave: false

  belongs_to :contact, class_name: 'Person'

  has_many :attachments, dependent: :destroy

  has_many :dates, -> { order(:start_at) }, dependent: :destroy, validate: true, inverse_of: :event
  has_many :questions, dependent: :destroy, validate: true

  has_many :application_questions, -> { where(admin: false) },
           class_name: 'Event::Question', inverse_of: :event
  has_many :admin_questions, -> { where(admin: true) },
           class_name: 'Event::Question', inverse_of: :event

  has_many :participations, dependent: :destroy
  has_many :people, through: :participations

  has_many :subscriptions, as: :subscriber, dependent: :destroy

  has_many :person_add_requests,
           foreign_key: :body_id,
           inverse_of: :body,
           class_name: 'Person::AddRequest::Event',
           dependent: :destroy

  ### VALIDATIONS

  validates_by_schema
  validates :dates, presence: { message: :must_exist }
  validates :group_ids, presence: { message: :must_exist }
  validates :application_opening_at, :application_closing_at,
            timeliness: { type: :date, allow_blank: true, before: ::Date.new(9999, 12, 31) }
  validates :description, :location, :application_conditions,
            length: { allow_nil: true, maximum: 2**16 - 1 }
  validate :assert_type_is_allowed_for_groups
  validate :assert_application_closing_is_after_opening
  validate :assert_required_contact_attrs_valid
  validate :assert_hidden_contact_attrs_valid

  ### CALLBACKS

  before_validation :set_self_in_nested
  before_validation :set_signature, if: :signature_confirmation?

  accepts_nested_attributes_for :dates, :application_questions, :admin_questions,
                                allow_destroy: true

  ### SERIALIZED ATTRIBUTES
  serialize :required_contact_attrs, Array
  serialize :hidden_contact_attrs, Array

  ### CLASS METHODS

  class << self

    # Default scope for event lists
    def list
      order_by_date.
        order(:name).
        preload_all_dates.
        distinct
    end

    def preload_all_dates
      all.extending(Event::PreloadAllDates)
    end

    def order_by_date
      joins(:dates).order('event_dates.start_at')
    end

    # Events with at least one date in the given year
    def in_year(year)
      year = Time.zone.today.year if year.to_i <= 0
      start_at = Time.zone.parse "#{year}-01-01"
      finish_at = start_at + 1.year
      joins(:dates).where(event_dates: { start_at: [start_at...finish_at] })
    end

    # Event with start and end-date overlay
    def between(start_date, end_date)
      joins(:dates).
        where('event_dates.start_at <= :end_date AND event_dates.finish_at >= :start_date ' \
              'OR event_dates.start_at <= :end_date AND event_dates.start_at >= :start_date',
              start_date: start_date, end_date: end_date).distinct
    end

    # Events from groups in the hierarchy of the given user.
    def in_hierarchy(user)
      with_group_id(user.groups_hierarchy_ids)
    end

    # Events belonging to the given group ids
    def with_group_id(group_ids)
      joins(:groups).where(groups: { id: group_ids })
    end

    # Events running now or in the future.
    def upcoming(midnight = Time.zone.now.midnight)
      joins(:dates).
        where('event_dates.start_at >= ? OR event_dates.finish_at >= ?', midnight, midnight)
    end

    # Events that are open for applications.
    def application_possible
      today = Time.zone.today
      where('events.application_opening_at IS NULL OR events.application_opening_at <= ?', today).
        where('events.application_closing_at IS NULL OR events.application_closing_at >= ?', today).
        where('events.maximum_participants IS NULL OR events.maximum_participants <= 0 OR ' \
            'events.participant_count < events.maximum_participants')
    end

    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      used_attributes.include?(attr)
    end

    def label
      model_name.human
    end

    def label_plural
      model_name.human(count: 2)
    end

    def type_name
      self == base_class ? 'simple' : name.demodulize.underscore
    end

    def all_types
      [Event] + Event.subclasses
    end

    # Return the event type with the given sti_name or raise an exception if not found
    def find_event_type!(sti_name)
      type = all_types.detect { |t| t.sti_name == sti_name }
      raise ActiveRecord::RecordNotFound, "No event type '#{sti_name}' found" if type.nil?

      type
    end

    def participant_types
      role_types.select(&:participant?)
    end

    # Return the role type with the given sti_name or raise an exception if not found
    def find_role_type!(sti_name)
      type = role_types.detect { |t| t.sti_name == sti_name }
      raise ActiveRecord::RecordNotFound, "No role '#{sti_name}' found" if type.nil?

      type
    end
  end


  ### INSTANCE METHODS

  delegate :participant_types, :find_role_type!, to: :singleton_class

  def to_s(_format = :default)
    name
  end

  def label_detail
    "#{number} #{group_names}"
  end

  def group_names
    groups.join(', ')
  end

  def supports_application_details?
    participant_types.present?
  end

  def application_duration
    Duration.new(application_opening_at, application_closing_at)
  end

  # May participants apply now?
  def application_possible?
    application_period_open? && (places_available? || waiting_list_available?)
  end

  def init_questions
    # do nothing by default
  end

  def course_kind?
    kind_class == Event::Kind && kind.present?
  end

  def duplicate # rubocop:disable Metrics/AbcSize,Metrics/MethodLength splitting this up does not make it better
    dup.tap do |event|
      event.groups = groups
      event.state = nil
      event.application_opening_at = nil
      event.application_closing_at = nil
      event.participant_count = 0
      event.applicant_count = 0
      event.teamer_count = 0
      application_questions.each do |q|
        event.application_questions << q.dup
      end
      admin_questions.each do |q|
        event.admin_questions << q.dup
      end
    end
  end

  def attr_used?(attr)
    self.class.used_attributes.include?(attr)
  end

  def places_available?
    maximum_participants.to_i.zero? || participant_count < maximum_participants
  end

  def waiting_list_available?
    self.class.supports_applications && attr_used?(:waiting_list) && waiting_list?
  end

  private

  def application_period_open?
    (!application_opening_at? || application_opening_at <= Time.zone.today) &&
    (!application_closing_at? || application_closing_at >= Time.zone.today)
  end

  def assert_type_is_allowed_for_groups
    master = groups.try(:first)
    return unless master

    if groups.any? { |g| g.class != master.class }
      errors.add(:group_ids, :must_have_same_type)
    elsif type && !master.class.event_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end
  end

  def assert_application_closing_is_after_opening
    unless application_duration.meaningful?
      errors.add(:application_closing_at, :must_be_after_opening)
    end
  end

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    (dates + application_questions + admin_questions).each do |e|
      e.event = self unless e.frozen?
    end
  end

  def valid_contact_attr?(attr)
    (
      ParticipationContactData.contact_attrs +
      ParticipationContactData.contact_associations
    ).map(&:to_s).include?(attr.to_s)
  end

  def assert_required_contact_attrs_valid
    required_contact_attrs.map(&:to_s).each do |a|
      unless valid_contact_attr?(a) &&
          ParticipationContactData.contact_associations.
             map(&:to_s).exclude?(a)
        errors.add(:base, :contact_attr_invalid, attribute: a)
      end

      if hidden_contact_attrs.include?(a)
        errors.add(:base, :contact_attr_hidden_required, attribute: a)
      end
    end
  end

  def assert_hidden_contact_attrs_valid
    hidden_contact_attrs.map(&:to_sym).each do |a|
      unless valid_contact_attr?(a)
        errors.add(:base, :contact_attr_invalid, attribute: a)
      end
      if ParticipationContactData.mandatory_contact_attrs.include?(a)
        errors.add(:base, :contact_attr_mandatory, attribute: a)
      end
    end
  end

  def set_signature
    self.signature = true
  end

end
