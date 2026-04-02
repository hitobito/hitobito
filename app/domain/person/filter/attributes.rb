#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Attributes < Person::Filter::Base
  include Filter::Attributes

  self.model_class = Person

  def apply(scope)
    super.merge(years_scope)
  end

  private

  def years_constraint
    @years_constraint ||= constraints.find { |tuple| tuple[:key] == "years" }
  end

  def generic_constraints
    @generic_constraints ||= constraints - [years_constraint]
  end

  def years_scope
    return Person.all unless years_constraint

    value, constraint = years_constraint.values_at("value", "constraint")
    value = value.to_i
    case constraint.to_s
    when "greater" then years_greater_scope(value)
    when "smaller" then years_smaller_scope(value)
    when "equal" then years_equal_scope(value)
    when "blank" then years_blank_scope(value)
    else raise("unexpected constraint: #{constraint.inspect}")
    end
  end

  def years_smaller_scope(value)
    date_value = Time.zone.now.to_date - value.to_i.years
    Person.where("birthday > ?", date_value)
  end

  def years_greater_scope(value)
    # Account for weird definition of age, depending on greater_than comparison...
    date_value = Time.zone.now.to_date - value.to_i.years - 1.year + 1.day
    Person.where(birthday: ...date_value)
  end

  def years_equal_scope(value)
    years_smaller_scope(value + 1).merge(years_greater_scope(value - 1))
  end

  def years_blank_scope(value)
    Person.where(birthday: nil)
  end
end
