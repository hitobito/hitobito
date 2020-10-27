class PersonDuplicateDecorator < ApplicationDecorator
  decorates :person_duplicate
  decorates_association :person_1
  decorates_association :person_2

end
