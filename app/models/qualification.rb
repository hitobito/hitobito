# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  person_id             :integer          not null
#  qualification_type_id :integer          not null
#  start_at              :date             not null
#  finish_at             :date
#

class Qualification < ActiveRecord::Base
  
  attr_accessible :qualification_type_id, :qualification_type, :start_at
  
  belongs_to :person
  belongs_to :qualification_type
  
  before_validation :set_finish_at
  
  
  private
  
  def set_finish_at
    if start_at? && qualification_type && !qualification_type.validity.nil?
      self.finish_at = (start_at + qualification_type.validity.years).end_of_year
    end
  end
  
end
