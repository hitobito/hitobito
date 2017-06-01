# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  type                        :string
#  name                        :string           not null
#  number                      :string
#  motto                       :string
#  cost                        :string
#  maximum_participants        :integer
#  contact_id                  :integer
#  description                 :text
#  location                    :text
#  application_opening_at      :date
#  application_closing_at      :date
#  application_conditions      :text
#  kind_id                     :integer
#  state                       :string(60)
#  priorization                :boolean          default(FALSE), not null
#  requires_approval           :boolean          default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  participant_count           :integer          default(0)
#  application_contact_id      :integer
#  external_applications       :boolean          default(FALSE)
#  applicant_count             :integer          default(0)
#  teamer_count                :integer          default(0)
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string
#  creator_id                  :integer
#  updater_id                  :integer
#  applications_cancelable     :boolean          default(FALSE), not null
#

class Event::Course < Event

  # This statement is required because this class would not be loaded otherwise.
  require_dependency 'event/course/role/participant'

  self.used_attributes += [:number, :kind_id, :state, :priorization, :group_ids, :requires_approval]

  self.role_types = [Event::Role::Leader,
                     Event::Role::AssistantLeader,
                     Event::Role::Cook,
                     Event::Role::Helper,
                     Event::Role::Treasurer,
                     Event::Role::Speaker,
                     Event::Course::Role::Participant]

  self.supports_applications = true

  self.kind_class = Event::Kind


  belongs_to :kind

  validates :kind_id, presence: true, if: -> { used_attributes.include?(:kind_id) }


  def label_detail
    label = used_attributes.include?(:kind_id) ? "#{kind.short_name} " : ''
    label << "#{number} #{group_names}"
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
