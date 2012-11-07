module Jubla::Event::Camp::AffiliateCoach
  extend ActiveSupport::Concern
  
  included do

    attr_accessible :coach_id
    attr_accessor :coach_id
    attr_writer :coach

    self.role_types += [::Event::Camp::Role::Coach]

    after_save :create_coach

  end

  def coach
    if new_record?
      Person.find(@coach_id) if @coach_id.present?
    else
      @coach ||= coach_participation.try(:person)
    end
  end

  def coach_id
    @coach_id ||= coach.try(:id)
  end

  def coach_participation
    @coach_participation ||= participations.joins(:roles).where(event_roles: {type: ::Event::Camp::Role::Coach.sti_name}).first
  end

  private
  def create_coach
    if coach_participation.try(:person_id) != coach_id
      if coach_participation
        coach_participation.roles.where(event_roles: {type: ::Event::Camp::Role::Coach.sti_name}).first.destroy
        @coach_participation = nil # remove it from cache to
      end
      if coach_id.present?
        participation = participations.where(person_id: coach_id).first_or_create
        role = ::Event::Camp::Role::Coach.new
        role.participation = participation
        role.save!
      end
    end
  end

end
