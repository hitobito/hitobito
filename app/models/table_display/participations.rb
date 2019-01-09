class TableDisplay::Participations < TableDisplay
  def available
    default_columns + Person.column_names - excluded_columns
  end

  def defaults
    %w()
  end

  def excluded
    %w(first_name last_name nickname address zip_code town) + Person::INTERNAL_ATTRS.collect(&:to_s)
  end
end
