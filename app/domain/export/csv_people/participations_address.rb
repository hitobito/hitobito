module Export::CsvPeople
  # handles participations
  class ParticipationsAddress < PeopleAddress
    include ParticipationSupport
  end
end
