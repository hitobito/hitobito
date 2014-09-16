# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text
#  created_at             :datetime
#  updated_at             :datetime
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#  qualified              :boolean
#

class Event::Participation < ActiveRecord::Base

  schema_validations except_type: :uniqueness

  self.demodulized_route_keys = true

  attr_accessor :enforce_required_answers

  ### ASSOCIATIONS

  belongs_to :event
  belongs_to :person

  belongs_to :application, dependent: :destroy, validate: true

  has_many :roles, dependent: :destroy

  has_many :answers, dependent: :destroy, validate: true


  accepts_nested_attributes_for :answers, :application


  ### VALIDATIONS

  validates :person_id,
            uniqueness: { scope: :event_id }
  validates :additional_information,
            length: { allow_nil: true, maximum: 2**16 - 1 }


  ### CALLBACKS

  before_validation :set_self_in_nested

  # There may be old participations without roles, so they must
  # update the count directly.
  after_destroy :update_participant_count


  ### CLASS METHODS

  class << self
    # Order people by the order participation types are listed in their event types.
    def order_by_role(event_type)
      joins(:roles).order(order_by_role_statement(event_type))
    end

    def order_by_role_statement(event_type)
      statement = 'CASE event_roles.type '
      event_type.role_types.each_with_index do |t, i|
        statement << "WHEN '#{t.sti_name}' THEN #{i} "
      end
      statement << 'END'
    end

    def active
      where(active: true)
    end

    def pending
      where(active: false)
    end

    def upcoming
      joins(event: :dates).where('event_dates.start_at >= ?', ::Date.today).uniq
    end

  end


  ### INSTANCE METHODS

  def init_answers
    if answers.blank?
      event.questions.each do |q|
        a = q.answers.new
        a.question = q # without this, only the id is set
        answers << a
      end
    end
  end

  private

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    answers.each { |e| e.participation = self unless e.frozen? }
  end

  def update_participant_count
    event.refresh_participant_counts!
  end
end
