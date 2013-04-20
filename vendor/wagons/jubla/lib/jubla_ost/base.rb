module JublaOst
  class Base < ActiveRecord::Base
    self.abstract_class = true

    establish_connection JublaOst::Config.database

    class << self
      def migrate
        ActiveRecord::Base.transaction do
          sanitize_source

          JublaOst::Region.migrate

          ActiveRecord::Base.record_timestamps = false
          JublaOst::Kurs.migrate
          JublaOst::Person.migrate
          ActiveRecord::Base.record_timestamps = true
        end
      end

      def cache
        @cache ||= {}
      end
      
      private

      def combine(separator, *values)
        values.collect(&:presence).compact.join(separator)
      end

      def sanitize_source
        sanitize_dates(JublaOst::PersonSchar, 'Eintritt')
        sanitize_dates(JublaOst::PersonSchar, 'Austritt')
        sanitize_dates(JublaOst::Person, 'Geburtstag')
        sanitize_emails
      end

      def sanitize_dates(clazz, attr)
        range = [0000] + (1900..2013).to_a
        range.each do |year|
          clazz.where("#{attr} LIKE ?", "#{year}-00-00%").
                update_all("#{attr} = '#{year}-01-01'")
        end
      end

      def sanitize_emails
        Person.where(Email: 'denise17@bluemailch').update_all(Email: 'denise17@bluemail.ch')
        Person.where(Email: 'cludi.waltert@bluewin,ch').update_all(Email: 'cludi.waltert@bluewin.ch')
        Person.where(Email: 'joergst@bluewin').update_all(Email: 'joergst@bluewin.ch')
        Person.where(Email: 'juhu67@bluewin').update_all(Email: 'juhu67@bluewin.ch')
        Person.where(Email: 'benno.kraemer@bluewin').update_all(Email: 'benno.kraemer@bluewin.ch')
        Person.where(Email: 'cma@x-tra').update_all(Email: 'cma@x-tra.ch')
        Person.where(Email: 'm.kilchmann@shinternet').update_all(Email: 'm.kilchmann@shinternet.ch')
        Person.where(Email: 'test@test').update_all(Email: nil)
      end
    end
  end
end