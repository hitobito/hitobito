class MoneyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless (value / 0.05).frac == 0.0
      record.errors[attribute] << I18n.t("errors.messages.invalid_money")
    end
  end
end
