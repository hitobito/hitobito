module Export
  module Courses
    class List
      attr_reader :courses, :row_class

      def initialize(courses)
        @courses = courses
      end

      def rows
        @rows ||= courses.map { |course| new_row(course) }
      end

      def to_csv(generator)
        generator << labels.values
        rows.each do |row|
          generator << values(row)
        end
      end

      def labels
        course_labels
          .merge(date_labels)
          .merge(prefixed_contactable_labels(:contact))
          .merge(prefixed_contactable_labels(:leader))
      end

      def contactable_keys
        [:name, :address, :zip_code, :town, :email, :phone_numbers]
      end

      def max_dates
        3
      end

      private
      def new_row(course)
        Row.new(course, self)
      end

      def options
        { col_sep: Settings.csv.separator.strip }
      end

      def values(row)
        labels.keys.map {|key| row.hash.fetch(key) }
      end


      def course_labels
        { group_names: "Organisatoren",
          number: human(:number),
          kind: Event::Kind.model_name.human,
          description: human(:description),
          state: human(:state),
          location: human(:location) }
      end

      def human(key)
        Event::Course.human_attribute_name(key)
      end

      def date_labels
        max_dates.times.each_with_object({}) do |i, hash|
          hash[:"date_#{i}_label"] = "Datum #{i + 1} #{Event::Date.human_attribute_name(:label)}"
          hash[:"date_#{i}_location"] = "Datum #{i + 1} #{Event::Date.human_attribute_name(:location)}"
          hash[:"date_#{i}_duration"] = "Datum #{i + 1} Zeitraum"
        end
      end

      def prefixed_contactable_labels(prefix)
        contactable_keys.each_with_object({}) do |key, hash|
          hash[:"#{prefix}_#{key}"] = "#{translated_prefix(prefix)} #{Person.human_attribute_name(key)}"
        end
      end

      def translated_prefix(prefix)
        case prefix
        when :leader then Event::Role::Leader.model_name.human
        when :contact then Event::Course.human_attribute_name(:contact)
        else prefix
        end
      end
    end
  end
end
