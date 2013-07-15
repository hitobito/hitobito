module Export
  module Courses

    def self.export_list(courses)
      Export::Csv::Generator.new(Export::Courses::List.new(courses)).csv
    end

  end
end
