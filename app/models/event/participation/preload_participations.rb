class Event::Participation::PreloadParticipations
  def self.preload(participations, includes = nil)
    ActiveRecord::Associations::Preloader.new(
      records: participations.select { |participation| participation.participant_type.eql?(Person.sti_name) },
      associations: includes || [:roles, :event, answers: [:question], participant: [:additional_emails, :phone_numbers]]
    ).call
    ActiveRecord::Associations::Preloader.new(
      records: participations.select { |participation| participation.participant_type.eql?(Event::Guest.sti_name) },
      associations: includes || [:roles, :event, :participant, answers: [:question]]
    ).call
  end
end
