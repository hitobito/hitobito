#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "vcard"

module Export::Vcf
  class Vcards
    def generate(people)
      vcards = []
      people.each do |person|
        vcards << vcard(person)
      end
      vcards.join
    end

    private

    def name(card, person)
      card.name do |n|
        n.given = person.first_name.to_s
        n.family = person.last_name.to_s
      end
      if person.nickname.present?
        card.nickname = person.nickname
      end
    end

    def birthday(card, person)
      if person.birthday.present?
        card.birthday = person.birthday
      end
    end

    def address_empty?(person)
      person.address.blank? && person.town.blank? &&
        person.zip_code.blank? && person.country.blank?
    end

    def address(card, person)
      unless address_empty?(person)
        card.add_addr do |a|
          a.street = person.address.to_s
          a.locality = person.town.to_s
          a.postalcode = person.zip_code.to_s
          a.country = person.country.to_s
        end
      end
    end

    def emails(card, person)
      if person.email.present?
        card.add_email(person.email) { |e| e.preferred = true }
      end
      person.additional_emails.each do |email|
        next unless email.public?
        card.add_email(email.email) do |e|
          e.location = email.label
          e.preferred = false
        end
      end
    end

    def phones(card, person)
      person.phone_numbers.each do |phone|
        next unless phone.public?
        card.add_tel(phone.number) { |t| t.location = phone.label }
      end
    end

    def vcard(person)
      Vcard::Vcard::Maker.make2 do |m|
        name(m, person)
        birthday(m, person)
        address(m, person)
        emails(m, person)
        phones(m, person)
      end
    end
  end
end
