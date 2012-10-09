Fabricator(:event_date, class_name: 'Event::Date') do
  event
  label { 'Hauptanlass' }
  start_at { Date.today }
  finish_at { |date| date[:start_at] + 7.days }
end
