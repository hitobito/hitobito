class NoAttachmentsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.body.attachments.any?
      record.errors[attribute] << I18n.t('errors.messages.attachments_not_allowed')
    end
  end
end
