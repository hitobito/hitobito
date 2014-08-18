# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                               :integer          not null, primary key
#  type                             :string(255)
#  name                             :string(255)      not null
#  number                           :string(255)
#  motto                            :string(255)
#  cost                             :string(255)
#  maximum_participants             :integer
#  contact_id                       :integer
#  description                      :text
#  location                         :text
#  application_opening_at           :date
#  application_closing_at           :date
#  application_conditions           :text
#  kind_id                          :integer
#  state                            :string(60)
#  priorization                     :boolean          default(FALSE), not null
#  requires_approval                :boolean          default(FALSE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  participant_count                :integer          default(0)
#  application_contact_id           :integer
#  external_applications            :boolean          default(FALSE)
#  representative_participant_count :integer          default(0)
#

class Event::Course < Event

  # This statement is required because this class would not be loaded otherwise.
  require_dependency 'event/course/role/participant'

  self.used_attributes += [:number, :kind_id, :state, :priorization, :requires_approval]

  self.role_types = [Event::Role::Leader,
                     Event::Role::AssistantLeader,
                     Event::Role::Cook,
                     Event::Role::Treasurer,
                     Event::Role::Speaker,
                     Event::Course::Role::Participant]

  self.supports_applications = true

  self.kind_class = Event::Kind


  belongs_to :kind

  validates :kind_id, presence: true


  def label_detail
    "#{kind.short_name} #{number} #{group_names}"
  end

  # Does this event provide qualifications
  def qualifying?
    kind_id? && kind.qualifying?
  end

  # The date on which qualification obtained in this course start
  def qualification_date
    @qualification_date ||= begin
      last = dates.reorder('event_dates.start_at DESC').first
      last.finish_at || last.start_at
    end.to_date
  end

  def start_date
    @start_date ||= dates.first.start_at.to_date
  end

  def init_questions
    if questions.blank?
      Event::Question.global.each do |q|
        questions << q.dup
      end
    end
  end

end
