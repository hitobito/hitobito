# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#  start_at              :date             not null
#  finish_at             :date
#

class Qualification < ActiveRecord::Base
  
  attr_accessible :qualification_kind_id, :qualification_kind, :start_at
  
  belongs_to :person
  belongs_to :qualification_kind
  
  before_validation :set_finish_at
  
  validates :qualification_kind_id, uniqueness: {scope: [:person_id, :start_at]}
  
  class << self
    def active
      today = Date.today
      where("qualifications.start_at <= ? AND qualifications.finish_at >= ?", today, today)
    end
    
  end
  
  def active?
    duration.active?
  end
  
  def duration
    Duration.new(start_at, finish_at)
  end

  def to_s
    "#{qualification_kind} (#{I18n.l(finish_at)})"
  end
  
  private

  scope :order_by_date, order('finish_at DESC')
  
  def set_finish_at
    if start_at? && qualification_kind && !qualification_kind.validity.nil?
      self.finish_at = (start_at + qualification_kind.validity.years).end_of_year
    end
  end
  
end
