# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

class Event::Role < ActiveRecord::Base

  # rubocop:disable ConstantName

  Permissions = [:event_full, :participations_full, :participations_read, :qualify]

  # The different role kinds.
  # leaders and participants may qualify, helpers not.
  # kind nil is for restricted roles.
  Kinds = [:leader, :helper, :participant]

  # rubocop:enable ConstantName

  include NormalizedLabels

  ### ATTRIBUTES

  class_attribute :permissions, :kind

  # The permissions this role has in the corresponding event.
  self.permissions = []

  # The kind of this role.
  #
  # If the value is nil, the role does not actually participate in the event,
  # but is an external supervisor.
  self.kind = :helper

  self.demodulized_route_keys = true


  ### ASSOCIATIONS

  belongs_to :participation, validate: true

  has_one :event, through: :participation
  has_one :person, through: :participation


  ### CALLBACKS

  after_create :set_participation_active
  before_destroy :protect_applying_participant
  after_destroy :destroy_participation_for_last

  class << self
    def label
      model_name.human
    end

    # Whether this role is a leader type.
    def leader?
      kind == :leader
    end

    # Whether this role is a participant type.
    def participant?
      kind == :participant
    end

    # Whether this role is specially managed or open for general modifications.
    def restricted?
      kind.nil?
    end
  end


  ### INSTANCE METHODS

  def to_s(_format = :default)
    model_name = self.class.label
    label? ? "#{label} (#{model_name})" : model_name
  end

  def person_id
    person.try(:id)
  end

  def restricted?
    self.class.restricted?
  end

  private

  # A participation with at least one role is active
  def set_participation_active
    participation.update_attribute(:active, true) unless applying_participant?
    update_participant_count if self.class.participant?
  end

  def destroy_participation_for_last
    update_participant_count if self.class.participant?
    participation.destroy unless participation.roles.exists?
  end

  def protect_applying_participant
    if applying_participant? && participation.roles == [self]
      participation.update_attribute(:active, false)
      update_participant_count
      false # do not destroy
    end
  end

  def applying_participant?
    self.class.participant? && participation.application_id?
  end

  def update_participant_count
    event ||= participation.event
    event.refresh_participant_counts! if event
  end

end
