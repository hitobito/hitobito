module Import
  class PersonColumnGuesser
    attr_reader :columns, :headers, :mapping

    def initialize(headers)
      @headers = headers
      population_mapping
    end

    def [](key)
      mapping[key]
    end


    private
    def population_mapping
      @mapping = headers.each_with_object({}) do |header, memo|
        memo[header] = default_or_null_value(header)
      end
    end

    def default_or_null_value(header)
      Import::Person.fields.find { |field| field[:value].downcase[header.downcase] } || { key: nil }
    end
  end
end
