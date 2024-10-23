module Import::PersonDuplicate::Attributes
  extend ActiveSupport::Concern
  DUPLICATE_ATTRIBUTES = [
    :first_name,
    :last_name,
    :company_name,
    :zip_code,
    :birthday
  ]

  def duplicate_conditions(attrs)
    [""].tap do |conditions|
      append_duplicate_conditions(attrs, conditions)
      append_email_condition(attrs, conditions)
    end
  end

  def append_duplicate_conditions(attrs, conditions)
    existing_duplicate_attrs(attrs).each do |key, value|
      condition = conditions.first
      connector = condition.present? ? " AND " : nil
      comparison = if %w[first_name last_name company_name].include?(key.to_s)
        "#{key} = ?"
      else
        "(#{key} = ? OR #{key} IS NULL)"
      end
      conditions[0] = "#{condition}#{connector}#{comparison}"
      value = parse_date(value) if key.to_sym == :birthday
      conditions << value
    end
  end

  def append_email_condition(attrs, conditions)
    if attrs[:email].present?
      condition = conditions.first
      conditions[0] = if condition.present?
        "(#{condition}) OR email = ?"
      else
        "email = ?"
      end
      conditions << attrs[:email]
    end
  end

  def existing_duplicate_attrs(attrs)
    existing = attrs.select do |key, value|
      value.present? && DUPLICATE_ATTRIBUTES.include?(key.to_sym)
    end
    existing.delete(:birthday) unless parse_date(existing[:birthday])
    existing
  end

  def parse_date(date_string)
    if date_string.present?
      begin
        ActiveRecord::Type::Date.new.cast(date_string)
      rescue ArgumentError
        nil
      end
    end
  end
end
