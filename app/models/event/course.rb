# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#  condition_id           :integer
#

class Event::Course < Event

  # This statement is required because this class would not be loaded otherwise.
  require_dependency 'event/course/role/participant'

  self.role_types = [Event::Role::Leader,
                     Event::Role::AssistantLeader,
                     Event::Role::Cook,
                     Event::Role::Treasurer,
                     Event::Role::Speaker,
                     Event::Course::Role::Participant]
  self.participant_type = Event::Course::Role::Participant
  self.supports_applications = true

  attr_accessible :number, :kind_id, :state, :priorization, :requires_approval

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

end
