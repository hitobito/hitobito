require 'csv'
module Export
  module CsvPeople

    def self.export_address(people)
      export(PeopleAddress, people)
    end

    def self.export_full(people)
      export(PeopleFull,people)
    end

    def self.export_participations_address(participations)
      export(ParticipationsAddress,participations)
    end

    def self.export_participations_full(participations)
      export(ParticipationsFull,participations)
    end

    private

    def self.export(exporter, people)
      Export::Csv::Generator.new(exporter.new(people)).csv
    end
  end

end
