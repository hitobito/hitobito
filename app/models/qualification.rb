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
  
  
  private
  
  def set_finish_at
    if start_at? && qualification_kind && !qualification_kind.validity.nil?
      self.finish_at = (start_at + qualification_kind.validity.years).end_of_year
    end
  end
  
end
