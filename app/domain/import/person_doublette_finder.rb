module Import
  class PersonDoubletteFinder
    attr_reader :attrs

    DOUBLETTE_ATTRIBUTES = [
      :first_name,
      :last_name,
      :zip_code,
      :birthday
    ]

    def initialize(attrs)
      @attrs = attrs
    end

    def query
      criteria = attrs.select { |key, value| value.present? && DOUBLETTE_ATTRIBUTES.include?(key.to_sym) }
      criteria.delete(:birthday) unless parse_date(criteria[:birthday])

      conditions = ['']
      criteria.each do |key, value|
        conditions.first << " AND " if conditions.first.present?
        conditions.first << "#{key} = ?"
        value = parse_date(value) if key.to_sym == :birthday
        conditions << value
      end

      if attrs[:email].present?
        if conditions.first.present?
          conditions[0] = "(#{conditions[0]}) OR "
        end
        conditions.first << "email = ?"
        conditions << attrs[:email]
      end
      conditions
    end

    def find_and_update
      conditions = query
      return if conditions.first.blank?
      people = ::Person.includes(:roles).where(conditions).to_a

      if people.present?
        person = people.first
        if people.size == 1
          blank_attrs = attrs.select {|key, value| person.attributes[key].blank? }
          person.attributes = blank_attrs
        else
          person.errors.add(:base, "#{people.size} Treffer in Duplikatserkennung.")
        end
        person
      end
    end

    private
    def parse_date(date_string)
      if date_string.present?
        begin
          Time.zone.parse(date_string).to_date
        rescue
        end
      end
    end
  end
end
