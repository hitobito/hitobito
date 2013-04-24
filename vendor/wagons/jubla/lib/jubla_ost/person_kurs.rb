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
        cache = Kurs.questions[person_kurs.KUID]
        
        participation.answers.build(answer: vegi_answer(person_kurs), question_id: cache[:vegi].id)
        participation.answers.build(answer: abo_answer(person_kurs), question_id: cache[:abo].id)
        
        (1..6).each do |i|
          if question = cache[i]
            a = person_kurs.attributes["kurs#{i}"]
            participation.answers.build(answer: a, question_id: question.id)
          end
        end
      end
      
      def vegi_answers(person_kurs)
        person_kurs.vegetarisch == 1 ? 'ja' : 'nein'
      end
      
      def abo_answer(person_kurs)
        case person_kurs.billet
        when 'GA' then 'GA'
        when 'HT' then 'Halbtax / unter 16'
        else 'keine Vergünstigung'
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