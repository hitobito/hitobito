# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::CsvPeople
  class Participation < Export::CsvPeople::Person
    
    def initialize(participation)
      super(participation.person)
      merge!(roles: map_roles(participation.roles))
      merge!(additional_information: participation.additional_information)
      participation.answers.each do |answer|
        merge!(:"question_#{answer.question_id}" => answer.answer)
      end
    end

    def map_roles(roles)
      roles.map { |role| role  }.join(', ')
    end
  end
end