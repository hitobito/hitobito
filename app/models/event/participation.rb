# encoding: utf-8

# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  created_at             :datetime         not null
#  additional_information :text
#  updated_at             :datetime         not null
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#

class Event::Participation < ActiveRecord::Base
  
  schema_validations except_type: :uniqueness
  
  self.demodulized_route_keys = true
  
  attr_accessible :additional_information, :answers_attributes, :application_attributes
  
  
  ### ASSOCIATIONS
  
  belongs_to :event
  belongs_to :person
  
  belongs_to :application, dependent: :destroy, validate: true
  
  has_many :roles, dependent: :destroy

  has_many :answers, dependent: :destroy, validate: true

  
  
  accepts_nested_attributes_for :answers, :application
  
  
  ### VALIDATIONS
  
  validates :person_id, uniqueness: {scope: :event_id, message: 'Du hast dich für diesen Anlass bereits angemeldet.'}
  
  
  ### CALLBACKS
  
  before_validation :set_self_in_nested

  ### SCOPES
  scope :active, where(active: true)
  scope :pending, where(active: false)
  
  class << self
    # Order people by the order participation types are listed in their event types.
    def order_by_role(event_type)
      statement = "CASE event_roles.type "
      event_type.role_types.each_with_index do |t, i|
        statement << "WHEN '#{t.sti_name}' THEN #{i} "
      end
      statement << "END"
      joins(:roles).order(statement)
    end
    
    def upcoming
      joins(event: :dates).where('event_dates.start_at >= ?', ::Date.today).uniq
    end
    def leader_team(event)
      where('event_roles.type <> ?', event.participant_type.sti_name)
    end
    def participant_team(event)
      where('event_roles.type = ?', event.participant_type.sti_name)
    end
  end


  ### INSTANCE METHODS

  def init_answers
    if answers.blank?
      event.questions.each do |q|
        a = q.answers.new
        a.question = q # without this, only the id is set
        self.answers << a
      end
    end
  end
  
  def create_participant_role(event)
    transaction do
      unless event_id == event.id
        # change this participation to the new event
        self.event = event
        update_column(:event_id, event.id)
        update_answers(event)
      end
      # create role
      role = event.participant_type.new
      role.participation = self
      role.save!
    end
  end
  
  def remove_participant_role
    roles.where(type: event.participant_type.sti_name).destroy_all
  end
  
  private
  
  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    answers.each {|e| e.participation = self unless e.frozen? }
  end

  # update the existing set of answers so that one exists for every question of event.
  def update_answers(event)
    current_answers = answers.includes(:question)
    event.questions.each do |q|
      exists = current_answers.any? do|a| 
        a.question.question == q.question && a.question.choice_items == q.choice_items
      end
      answers.create(question_id: q.id) unless exists
    end
  end
end
