module Import
  class PersonColumnGuesser
    attr_reader :columns, :headers, :mapping, :params

    def initialize(headers, params={})
      @headers = headers
      @params = params

      population_mapping
    end

    def [](key)
      mapping[key]
    end


    private
    def population_mapping
      @mapping = headers.each_with_object({}) do |header, memo|
        memo[header] = find_field(header)
      end
    end

    def find_field(header)
       params_field(header) || import_person_field(header) || null_field
    end

    def params_field(header)
      params[header] && person_fields.find { |field| field[:key] == params[header] }
    end

    def import_person_field(header)
     person_fields.find { |field| field[:value].downcase[header.downcase] }
    end

    def null_field
      { key: nil }
    end

    def person_fields
      @person_fields ||= Import::Person.fields
    end

  end
end
