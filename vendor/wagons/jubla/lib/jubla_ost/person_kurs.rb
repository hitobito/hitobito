# encoding: utf-8
module JublaOst
  class PersonKurs < Base
    self.table_name = 'tmPersKurs'
    self.primary_key = 'KMID'

    belongs_to :kurs_basisgruppe, foreign_key: 'bg'

    class << self
      def migrate_person_kurse(current, legacy)
        where(PEID: legacy.PEID).where('KUID <> 0').includes(:kurs_basisgruppe).each do |person_kurs|
          create_participation(current, person_kurs)
        end
      end

      private

      def create_participation(current, person_kurs)
        if event_id = Kurs.cache[person_kurs.KUID]
          participation = Event::Participation.new
          participation.event_id = event_id
          participation.person = current
          assign_attributes(participation, person_kurs)
          unless participation.save
            puts "KMID=#{person_kurs.KMID} PEID=#{person_kurs.PEID} KUID=#{person_kurs.KUID}: #{participation.inspect} ist nicht gültig: #{participation.errors.full_messages.join(", ")}"

            unless participation.errors[:person_id].present?
              raise ActiveRecord::RecordInvalid, participation
            end
          end
        else
          puts "No Kurs with id=#{person_kurs.KUID} found while migrating participations of #{current.to_s}"
        end
      end

      def assign_attributes(participation, person_kurs)
        participation.additional_information = combine("\n", person_kurs.bemerkung, person_kurs.tnbemerkung)
        participation.active = true
        participation.created_at = participation.updated_at = person_kurs.Anmeldung || Time.zone.now

        migrate_answers(participation, person_kurs)
        migrate_role(participation, person_kurs.MSID, person_kurs.kurs_basisgruppe.try(:Name))
     end

      def migrate_answers(participation, person_kurs)
        cache = Kurs.questions[person_kurs.KUID]

        participation.answers.build(answer: vegi_answer(person_kurs), question_id: cache[:vegi].id)
        participation.answers.build(answer: abo_answer(person_kurs), question_id: cache[:abo].id)
      end

      def vegi_answer(person_kurs)
        person_kurs.vegetarisch == 1 ? 'ja' : 'nein'
      end

      def abo_answer(person_kurs)
        case person_kurs.billet
        when 'GA' then 'GA'
        when 'HT' then 'Halbtax / unter 16'
        else 'keine Vergünstigung'
        end
      end

      def migrate_role(participation, funktion, label)
        role = KursTnStatus.all[funktion].role.new
        role.participation = participation
        role.label = label
        participation.roles << role
      end
    end
  end
end