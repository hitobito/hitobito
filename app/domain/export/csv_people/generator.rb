module Export::CsvPeople
  # Generate using people class for headers and value mapping
  class Generator
    attr_reader :csv

    def initialize(people)
      @csv = CSV.generate(options) do |csv|
        csv << people.values
        people.list.each do |person|
          hash = people.create(person)
          csv << people.keys.map { |key| hash[key] }
        end
      end
    end

    def options
      { col_sep: Settings.csv.separator.strip }
    end
  end
end