class TableDisplay::People < TableDisplay
  def available
    defaults + Person.column_names - excluded
  end

  def defaults
    %w()
  end

  def excluded
    %w(first_name last_name nickname address zip_code town) +
      Person::INTERNAL_ATTRS.collect(&:to_s) +
      %w(picture primary_group_id)
  end
end
