module JublaOst
  class PersonKurs < Base
    self.table_name = 'tmPersKurs'
    self.primary_key = 'KMID'
    
    class < self
      def migrate_person_kurse(current, legacy)
        where(PEID: legacy.PEID) do |person_kurs|
          create_participation(current, person_kurs)
        end
      end
      
      private
      
      def create_participation(current, person_kurs)
        if event_id = Kurs.cache[person_kurs.KUID]
          course = Event::Course.find(event_id)
          participation = course.participations.build
          participation.person = current
          assign_attributes(participation, person_kurs)
          participation.save!
        else
          puts "No Kurs with id=#{person_kurs.KUID} found while migrating participations of #{current.to_s}"
        end
      end
      
      def assign_attributes(participation, person_kurs)
        participation.additional_information = combine("\n", person_kurs.bemerkung, person_kurs.tnbemerkung)
        participation.active = true
        participation.created_at = person_kurs.Anmeldung

        migrate_answers(participation, person_kurs)
        migrate_role(participation, person_kurs.MSID)
     end
      
      def migrate_answers(participation, person_kurs)
        # TODO migrate ÖV Abo and Vegi answers
        (1..6).each do |i|
          a = person_kurs.attributes["kurs#{i}"]
          if a.present?
            participation.answers.build(answer: a, question_id: )
          end
        end
      end
      
      def migrate_role(participation, funktion)
        role = KursTnStatus.all(funktion).role.new
        role.participation = participation
        participation.roles << role
      end
    end
  end
end