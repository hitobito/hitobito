# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#  external_applications  :boolean          default(FALSE)
#

class Event < ActiveRecord::Base

  # This statement is required because these classes would not be loaded correctly otherwise.
  # The price we pay for using classes as namespace.
  require_dependency 'event/date'
  require_dependency 'event/role'
  require_dependency 'event/restricted_role'
  require_dependency 'event/application_decorator'
  require_dependency 'event/role_decorator'
  require_dependency 'event/role_ability'

  ### ATTRIBUTES

  class_attribute :role_types,
                  :participant_type,
                  :leader_types,
                  :supports_applications,
                  :possible_states,
                  :kind_class

  # All participation roles that exist for this event
  self.role_types = [Event::Role::Leader,
                     Event::Role::AssistantLeader,
                     Event::Role::Cook,
                     Event::Role::Treasurer,
                     Event::Role::Speaker,
                     Event::Role::Participant]
  # The role of the participant
  self.participant_type = Event::Role::Participant
  # Are Event::Applications possible for this event type
  self.supports_applications = false
  # List of possible values for the state attribute.
  self.possible_states = []
  # The class used for the kind_id
  self.kind_class = nil

  attr_accessible :name, :motto, :cost, :maximum_participants, :contact_id,
                  :description, :location, :application_opening_at, :application_closing_at,
                  :application_conditions, :dates_attributes, :questions_attributes, :group_ids,
                  :external_applications


  ### ASSOCIATIONS

  has_and_belongs_to_many :groups

  belongs_to :contact, class_name: 'Person'

  has_many :dates, dependent: :destroy, validate: true, order: :start_at
  has_many :questions, dependent: :destroy, validate: true

  has_many :participations, dependent: :destroy
  has_many :people, through: :participations

  has_many :subscriptions, as: :subscriber, dependent: :destroy

  ### VALIDATIONS

  validates :dates, presence: { message: 'müssen ausgefüllt werden' }
  validates :group_ids, presence: { message: 'müssen vorhanden sein' }
  validates :application_opening_at, :application_closing_at,
            timeliness: { type: :date, allow_blank: true }
  validate :assert_type_is_allowed_for_groups
  validate :assert_application_closing_is_after_opening


  ### CALLBACKS

  before_validation :set_self_in_nested

  ### SCOPES

  scope :order_by_date, joins(:dates).order('event_dates.start_at')
  scope :preload_all_dates, scoped.extending(Event::PreloadAllDates)


  accepts_nested_attributes_for :dates, :questions, allow_destroy: true

  ### CLASS METHODS

  class << self
    # Events with at least one date in the given year
    def in_year(year)
      year = ::Date.today.year if year.to_i <= 0
      start_at = Time.zone.parse "#{year}-01-01"
      finish_at = start_at + 1.year
      joins(:dates).where(event_dates: { start_at: [start_at...finish_at] })
    end

    # Events with a start_at greater than argument
    def since(datetime)
      joins(:dates).where('event_dates.start_at >= ?', datetime)
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
    def upcoming
      midnight = Time.zone.now.midnight
      joins(:dates).
      where('event_dates.start_at >= ? OR event_dates.finish_at >= ?', midnight, midnight)
    end

    # Events that are open for applications.
    def application_possible
      today = ::Date.today
      where('events.application_opening_at IS NULL OR events.application_opening_at <= ?', today).
      where('events.application_closing_at IS NULL OR events.application_closing_at >= ?', today).
      where('events.maximum_participants IS NULL OR ' +
            'events.maximum_participants <= 0 OR ' +
            'events.participant_count < events.maximum_participants')
    end

    # Default scope for event lists
    def list
      order_by_date.
      includes(:groups, :kind).
      preload_all_dates.
      uniq
    end

    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      accessible_attributes.include?(attr)
    end

    def label
      model_name.human
    end

    def label_plural
      model_name.human(count: 2)
    end

    def type_name
      if self == base_class
        'simple'
      else
        name.demodulize.underscore
      end
    end

    # Return the event type with the given sti_name or raise an exception if not found
    def find_event_type!(sti_name)
      types = [Event] + Event.subclasses
      type = types.detect { |t| t.sti_name == sti_name }
      fail ActiveRecord::RecordNotFound, "No event '#{sti_name}' found" if type.nil?
      type
    end

    # Return the role type with the given sti_name or raise an exception if not found
    def find_role_type!(sti_name)
      type = role_types.detect { |t| t.sti_name == sti_name }
      fail ActiveRecord::RecordNotFound, "No role '#{sti_name}' found" if type.nil?
      type
    end
  end


  ### INSTANCE METHODS

  def to_s(format = :default)
    name
  end

  def label_detail
    "#{number} #{group_names}"
  end

  def group_names
    groups.join(', ')
  end

  def application_duration
    Duration.new(application_opening_at, application_closing_at)
  end

  # May participants apply now?
  def application_possible?
    (!application_opening_at? || application_opening_at <= ::Date.today) &&
    (!application_closing_at? || application_closing_at >= ::Date.today) &&
    (maximum_participants.to_i == 0 || participant_count < maximum_participants)
  end

  # Sum the participations with the participant role and store in :participant_count
  def refresh_participant_count!
    count = participations.joins(:roles).
                           where(event_roles: { type: participant_type.sti_name }).
                           count(distinct: true)
    update_column(:participant_count, count)
  end

  def init_questions
    # do nothing by default
  end

  def participations_for(*role_types)
    participations.joins(:roles).
                   where(event_roles: { type: role_types.map(&:sti_name) }).
                   includes(:person).
                   order_by_role(self.class).
                   merge(Person.order_by_name).
                   uniq
  end

  # gets a list of all user defined participation role labels for this event
  def participation_role_labels
    @participation_role_labels ||=
      Event::Role.joins(:participation).
                  where('event_participations.event_id = ?', id).
                  where('event_roles.label <> ""').
                  uniq.order(:label).
                  pluck(:label)
  end

  def course_kind?
    kind_class == Event::Kind && kind.present?
  end

  private

  def assert_type_is_allowed_for_groups
    if groups.present?
      master = groups.first
      if groups.any? { |g| g.class != master.class }
        errors.add(:group_ids, :must_have_same_type)
      elsif type && !master.class.event_types.collect(&:sti_name).include?(type)
        errors.add(:type, :type_not_allowed)
      end
    end
  end

  def assert_application_closing_is_after_opening
    unless application_duration.meaningful?
      errors.add(:application_closing_at, :must_be_after_opening)
    end
  end

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    (dates + questions).each { |e| e.event = self unless e.frozen? }
  end

end
