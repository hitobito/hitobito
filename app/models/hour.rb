# == Schema Information
#
# Table name: hours
#
#  id                                      :integer          not null, primary key
#  person_id                               :integer                             
#  event_id                                :integer                              
#  custom_item                             :string(1024)    
#  custom_item_date                        :date                       
#  volunteer_hours                         :integer                              
#  submitted_status                        :boolean                             
#  approved_status                         :boolean 

class Hour < ApplicationRecord
  belongs_to :event
  belongs_to :person, class_name: 'Person'

  # Virtual attribute to handle date range
  attr_accessor :start_date, :end_date

  # Callbacks to format and save the date range
  before_save :set_custom_item_date
    
  private

  def set_custom_item_date
    # If start_date and end_date are provided, store them as a range string
    if start_date.present? && end_date.present?
      self.custom_item_date = "#{start_date} - #{end_date}"
    end
  end
end  