# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_applications
#
#  id            :integer          not null, primary key
#  priority_1_id :integer          not null
#  priority_2_id :integer
#  priority_3_id :integer
#  approved      :boolean          default(FALSE), not null
#  rejected      :boolean          default(FALSE), not null
#  waiting_list  :boolean          default(FALSE), not null
#

class Event::Application < ActiveRecord::Base

  self.demodulized_route_keys = true

  ### ASSOCIATION

  has_one :participation

  has_one :event, through: :participation

  belongs_to :priority_1, class_name: 'Event' #::Course
  belongs_to :priority_2, class_name: 'Event' #::Course
  belongs_to :priority_3, class_name: 'Event' #::Course


  ### CLASS METHODS

  class << self
    def pending
      joins(:participation).
      where(event_participations: { active: false },
            rejected: false)
    end

    def label(args = {})
      model_name.human(args)
    end

    def label_plural
      model_name.human(count: 2)
    end
  end

  ### INSTANCE METHODS

  def contact
    event.contact
  end

  def priority(event)
    [1, 2, 3].detect { |i| send("priority_#{i}_id") == event.id }
  end
end
