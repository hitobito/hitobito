module Export::CsvPeople
  # handles participations
  class ParticipationsAddress < PeopleAddress
    
    attr_reader :participations

    def initialize(participations)
      @participations = participations
      super(participations.map(&:person))
      add_event_specifics
    end

    def list
      @participations
    end

    def create(participation)
      Export::CsvPeople::Participation.new(participation)
    end

    def add_event_specifics
    end
  end
end