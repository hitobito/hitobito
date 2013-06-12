module Jubla
  module Export
    module Courses
      module Row

        # adding advisor (lkb)
        def additional_attributes
          course.class.attr_used?(:advisor_id) ? contactable_attributes(:advisor, course.advisor) : {}
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
end
