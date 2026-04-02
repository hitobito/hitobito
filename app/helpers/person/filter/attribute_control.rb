#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::AttributeControl < Filter::AttributeControl
  delegate :country_select, to: :template

  def model_class
    Person
  end

  private

  def all_field_types
    safe_join([
      super,
      country_select_field,
      gender_select_field
    ])
  end

  def country_select_field
    country_select(
      filter_name_prefix,
      "value",
      {priority_countries: Settings.countries.prioritized, selected: value, include_blank: ""},
      control_html_options(control_classes: SELECT_CLASSES, class: "country_select_field")
    )
  end

  def gender_select_field
    gender_options = (Person::GENDERS + [""]).collect { |g| [g, Person.new.gender_label(g)] }
    select_tag(
      "#{filter_name_prefix}[value]",
      options_from_collection_for_select(gender_options, :first, :last, value),
      control_html_options(control_classes: SELECT_CLASSES, class: "gender_select_field")
    )
  end
end
