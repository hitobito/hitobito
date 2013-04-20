# encoding: utf-8
module JublaOst
  class Person < Base
    self.table_name = 'tPersonen'
    self.primary_key = 'PEID'

    class << self

      def migrate
        i = 0
        find_each do |legacy|
          if person = find_or_create_person(legacy)
            migrate_qualification(person, legacy)
            PersonFunktion.migrate_person_roles(person, legacy)
            PersonKurs.migrate_person_kurse(person, legacy)
          end
          print "\r #{i+=1} people processed "
        end
      end

      private

      def find_or_create_person(legacy)
        if legacy.Email.present?
          person = ::Person.find_by_email(legacy.Email.downcase)
          return person if person
        end

        return if legacy.no_names? && legacy.Zusatz.blank?

        person = ::Person.new
        assign_attributes(person, legacy)
        unless person.save
          puts "#{person.inspect} ist nicht gültig: #{person.errors.full_messages.join(", ")}"
          raise ActiveRecord::RecordInvalid, person
        end
        person
      end

      def assign_attributes(current, legacy)
        if legacy.no_names?
          current.company_name = legacy.Zusatz
          current.company = true
        else
          current.first_name = legacy.Vorname
          current.last_name = legacy.Name
          current.nickname = legacy.vulgo
        end
        current.address = combine("\n", legacy.Strasse, legacy.Postfach)
        current.zip_code = legacy.PLZ.to_i > 0 ? legacy.PLZ.to_i : nil
        current.town = legacy.Ort
        current.email = legacy.Email.downcase if legacy.Email
        current.birthday = legacy.Geburtstag
        current.gender = legacy.Gesch

        current.nationality = legacy.nation
        current.profession = legacy.Beruf
        current.bank_account = legacy.konto
        current.ahv_number_old = legacy.AHV
        current.insurance_company = legacy.versges
        current.insurance_number = legacy.verspol
        current.j_s_number = legacy.JSNr
        current.additional_information = combine("\n\n", legacy.Bemerkung, legacy.aboutme)

        current.created_at = legacy.Erfasst || Time.zone.now
        current.updated_at = legacy.ChangeDate || Time.zone.now
        # TODO set ChangePEID somehow
        current.password = legacy.Passwort if legacy.Passwort && legacy.Passwort.size >= 6

        build_phone_number(current, legacy.Tel1, 'Privat')
        build_phone_number(current, legacy.Tel2, 'Arbeit')
        build_phone_number(current, legacy.Mobil, 'Mobil')
        build_phone_number(current, legacy.Fax, 'Fax')

        parse_social_accounts(current, legacy)
      end

      def build_phone_number(current, number, label)
        if number.present?
          current.phone_numbers.build(number: number, label: label)
        end
      end

      def parse_social_accounts(current, legacy)
        #TODO
      end
      
      def migrate_qualification(person, legacy)
        if legacy.JSStufe.present?
          quali = person.qualifications.build
          quali.qualification_kind = QualificationKind.find(JublaOst::Config.qualification_kind_id(legacy.JSStufe))
          if legacy.JSAktualisierung.present?
            quali.start_at = Date.new(legacy.JSAktualisierung)
          end 
          quali.origin = legacy.JSKursnr
          quali.save!
        end
      end
    end

    def no_names?
      self.Vorname.blank? && self.Name.blank? && self.vulgo.blank?
    end
  end
end