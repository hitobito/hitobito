module Export
  module Courses
    class JublaList < List
      def initialize(courses)
        super(courses)
      end

      def labels
        super.merge(prefixed_contactable_labels(:advisor))
      end

      def contactable_keys
        super.push(:j_s_number)
      end

      def new_row(course)
        JublaRow.new(course,self)
      end
      private

      def translated_prefix(prefix)
        prefix == :advisor ?  "LKB" : super
      end
    end

    class JublaRow < Row
      # adding advisor (lkb)
      def additional_attributes
        contactable_attributes(:advisor, course.advisor)
      end

      # adding j_s_number for people
      def additional_contactable_attributes(contactable)
        case contactable
        when Person then  { j_s_number: contactable.j_s_number }
        else {}
        end
      end
    end

  end
end
