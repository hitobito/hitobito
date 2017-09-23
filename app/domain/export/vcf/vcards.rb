# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'vcard'

module Export::Vcf
  class Vcards

    def generate(people)
      vcards = []
      people.each do |person|
        vcards << vcard(person)
      end
      vcards.join;
    end
    
    
    private
    
    def vcard(person)
      vcard = Vcard::Vcard::Maker.make2 do |m|
        m.name do |n|
          n.given = person.first_name.presence || ""
          n.family = person.last_name.presence || ""
        end
        if person.nickname.present?
          m.nickname = person.nickname
        end
        if person.address.present? || person.town.present? || person.zip_code.present? || person.country.present?
          m.add_addr do |a|
            a.street = person.address.presence || ""
            a.locality = person.town.presence || ""
            a.postalcode = person.zip_code.presence || ""
            a.country = person.country.presence || ""
          end
        end
        if person.email.present?
          m.add_email(person.email) { |e| e.preferred = true }
        end
        person.additional_emails.each do |email|
          if email.public? 
            m.add_email(email.email) { |e| e.location = email.label; e.preferred = false }
          end
        end
        person.phone_numbers.each do |phone|
          if phone.public?
            m.add_tel(phone.number) { |t| t.location = phone.label }
          end
        end
        if person.birthday.present?
          m.birthday = person.birthday
        end
      end
      vcard
    end
  end
end
