# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'csv'
module Export
  module CsvPeople

    def self.export_address(people)
      export(PeopleAddress, people)
    end

    def self.export_full(people)
      export(PeopleFull, people)
    end

    def self.export_participations_address(participations)
      export(ParticipationsAddress, participations)
    end

    def self.export_participations_full(participations)
      export(ParticipationsFull, participations)
    end

    private

    def self.export(exporter, people)
      Export::Csv::Generator.new(exporter.new(people)).csv
    end
  end

end
