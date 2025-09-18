# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactableDecorator
  def address
    model.address
  end

  def contact_name
    return decorated_model.address_name if decorated_model.respond_to?(:address_name)

    content_tag(:strong, to_s)
  end

  def complete_address # rubocop:disable Metrics/AbcSize
    html = "".html_safe

    prepend_complete_address(html)

    html << address_care_of << br if address_care_of?
    html << model.address << br if model.address.present?
    html << postbox << br if postbox?
    html << zip_code.to_s if zip_code?
    html << " " << town if town?
    html << country_unless_ignored

    content_tag(:p, html)
  end

  def all_additional_addresses(only_public = true)
    nested_values(additional_addresses, only_public) do |address|
      [address.value, invoice_icon(address)]
    end
  end

  def complete_contact
    contact_name +
      complete_address +
      primary_email +
      all_additional_emails(true) +
      all_phone_numbers(true) +
      all_additional_addresses(true) +
      all_social_accounts(true)
  end

  def primary_email
    if email.present?
      content_tag(:p, safe_join([h.mail_to(email), block_icon(email)].compact_blank, " "))
    end
  end

  def all_emails(only_public = true)
    "".html_safe <<
      primary_email <<
      all_additional_emails(only_public)
  end

  def all_additional_emails(only_public = true)
    nested_values(additional_emails, only_public) do |email|
      [h.mail_to(email.value), [block_icon(email.value), invoice_icon(email)]]
    end
  end

  def all_phone_numbers(only_public = true)
    nested_values(phone_numbers, only_public) do |number|
      h.link_to(number.value, "tel:#{number.value}")
    end
  end

  def all_social_accounts(only_public = true)
    nested_values(social_accounts, only_public) do |social_account|
      h.auto_link_value(social_account.value)
    end
  end

  def block_icon(email)
    return unless email_blocked?(email)

    h.icon("exclamation-triangle", class: "text-danger",
      title: h.t("contactable.contact_data.blocked_mail_tooltip_title"))
  end

  def email_blocked?(email)
    if context[:blocked_emails]
      context[:blocked_emails].include?(Bounce.normalize_email(email))
    else
      Bounce.blocked?(email)
    end
  end

  private

  def nested_values(values, only_public)
    html = values.collect do |v|
      next unless !only_public || v.public?

      val, suffix = block_given? ? yield(v) : v.value
      h.value_with_muted(val, safe_join([v.translated_label, *suffix].compact_blank, " "))
    end.compact

    html = h.safe_join(html, br)
    content_tag(:p, html) if html.present?
  end

  def invoice_icon(contact_account)
    return unless contact_account.try(:invoices?)

    h.icon("money-bill-alt", class: "muted",
      title: h.t("contactable.contact_data.invoices_tooltip_title"))
  end

  def br
    h.tag(:br)
  end

  def country_unless_ignored
    html = "".html_safe
    unless ignored_country?
      html << br if zip_code? || town?
      html << country_label
    end
    html
  end

  def prepend_complete_address(_html)
  end

  def decorated_model
    @decorated_model ||= model.decorate
  end
end
