# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::CsvPeople

  # Attributes of people we want to include
  class PeopleAddress
    attr_reader :people, :hash
    delegate :[], :merge!, :keys, :values, to: :hash

    def initialize(people)
      @people = people
      @hash = {}

      attributes.each { |attr| merge!(attr => translate(attr)) }
      merge!(roles: 'Rollen')
      add_associations
    end

    def to_csv(csv)
      csv << values
      list.each do |person|
        hash = create(person)
        csv << keys.map { |key| hash[key] }
      end
    end

    private

    def model_class
      ::Person
    end

    def list
      people
    end

    def create(person)
      Export::CsvPeople::Person.new(person)
    end

    def attributes
      [:first_name, :last_name, :nickname, :company_name, :company, :email,
       :address, :zip_code, :town, :country, :gender, :birthday]
    end

    def translate(attr)
      model_class.human_attribute_name(attr)
    end

    def add_associations
      merge!(labels(people.map(&:phone_numbers).flatten.select(&:public?), Accounts.phone_numbers))
    end

    def labels(collection, mapper)
      collection.map(&:label).uniq.each_with_object({}) do |label, obj|
        obj[mapper.key(label)] = mapper.human(label) if label.present? # label should always be present
      end
    end
  end
end
