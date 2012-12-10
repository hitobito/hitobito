require 'csv'
module Export
  module CsvPeople

    def self.export_address(people)
      Generator.new(PeopleAddress.new(people)).csv
    end

    def self.export_full(people)
      Generator.new(PeopleFull.new(people)).csv
    end

    def self.export_participations_address(participations)
      Generator.new(ParticipationsAddress.new(participations)).csv
    end

    def self.export_participations_full(participations)
      Generator.new(ParticipationsFull.new(participations)).csv
    end

  end

end
