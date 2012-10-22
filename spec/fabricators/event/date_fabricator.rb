# == Schema Information
#
# Table name: event_dates
#
#  id        :integer          not null, primary key
#  event_id  :integer          not null
#  label     :string(255)
#  start_at  :datetime
#  finish_at :datetime
#

Fabricator(:event_date, class_name: 'Event::Date') do
  event
  label { 'Hauptanlass' }
  start_at { Date.today }
  finish_at { |date| date[:start_at] + 7.days }
end
