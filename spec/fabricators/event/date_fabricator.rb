# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_dates
#
#  id        :integer          not null, primary key
#  event_id  :integer          not null
#  label     :string(255)
#  start_at  :datetime
#  finish_at :datetime
#  location  :string(255)
#

Fabricator(:event_date, class_name: 'Event::Date') do
  event
  label { 'Hauptanlass' }
  start_at { Date.today }
  finish_at { |date| date[:start_at] + 7.days }
end
