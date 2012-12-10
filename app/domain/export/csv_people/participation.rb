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