# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  applicant_count             :integer          default(0)
#  application_closing_at      :date
#  application_conditions      :text(16777215)
#  application_opening_at      :date
#  applications_cancelable     :boolean          default(FALSE), not null
#  cost                        :string(255)
#  description                 :text(16777215)
#  display_booking_info        :boolean          default(TRUE), not null
#  external_applications       :boolean          default(FALSE)
#  hidden_contact_attrs        :text(16777215)
#  location                    :text(16777215)
#  maximum_participants        :integer
#  motto                       :string(255)
#  name                        :string(255)      not null
#  number                      :string(255)
#  participant_count           :integer          default(0)
#  participations_visible      :boolean          default(FALSE), not null
#  priorization                :boolean          default(FALSE), not null
#  required_contact_attrs      :text(16777215)
#  requires_approval           :boolean          default(FALSE), not null
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string(255)
#  state                       :string(60)
#  teamer_count                :integer          default(0)
#  type                        :string(255)
#  waiting_list                :boolean          default(TRUE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  application_contact_id      :integer
#  contact_id                  :integer
#  creator_id                  :integer
#  kind_id                     :integer
#  updater_id                  :integer
#
# Indexes
#
#  index_events_on_kind_id  (kind_id)
#

# A course is a specialised Event that has by default applications,
# preconditions and may give a qualification after attending it.
class Event::Course < Event

  # This statement is required because this class would not be loaded otherwise.
  require_dependency "event/course/role/participant"

  self.used_attributes += [:number, :kind_id, :state, :priorization, :group_ids,
                           :requires_approval, :display_booking_info, :waiting_list]

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
    label = used_attributes.include?(:kind_id) ? "#{kind.short_name} " : ""
    "#{label}#{number} #{group_names}"
  end

  # Does this event provide qualifications
  def qualifying?
    kind_id? && kind.qualifying?
  end

  # The date on which qualification obtained in this course start
  def qualification_date
    @qualification_date ||= begin
      last = dates.reorder("event_dates.start_at DESC").first
      last.finish_at || last.start_at
    end.to_date
  end

  def start_date
    @start_date ||= dates.first.start_at.to_date
  end

  def init_questions
    if application_questions.blank?
      Event::Question.application.global.each do |q|
        application_questions << q.dup
      end
    end
  end

end
