#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Invoices
  class List < Export::Tabular::Base
    INCLUDED_ATTRS = %w[title sequence_number state esr_number description
      recipient_email recipient_address sent_at due_at
      cost vat total amount_paid].freeze

    CUSTOM_METHODS = %w[cost_centers accounts payments]

    ADDRESS_ATTRS = %w[recipient_company_name recipient_name
      recipient_address_care_of recipient_street recipient_housenumber
      recipient_postbox recipient_zip_code recipient_town recipient_country
      payee_name payee_street payee_housenumber payee_zip_code payee_town
      payee_country]

    self.model_class = Invoice
    self.row_class = Export::Tabular::Invoices::Row

    def attributes
      (INCLUDED_ATTRS + CUSTOM_METHODS + ADDRESS_ATTRS).collect(&:to_sym)
    end

    def recipient_company_name_label = recipient_label(:company_name)

    def recipient_name_label = recipient_label(:name)

    def recipient_address_care_of_label = recipient_label(:address_care_of)

    def recipient_street_label = recipient_label(:street)

    def recipient_housenumber_label = recipient_label(:housenumber)

    def recipient_postbox_label = recipient_label(:postbox)

    def recipient_zip_code_label = recipient_label(:zip_code)

    def recipient_town_label = recipient_label(:town)

    def recipient_country_label = recipient_label(:country)

    private

    def recipient_label(attribute)
      [I18n.t("activerecord.attributes.invoice.recipient"),
        I18n.t("activerecord.attributes.invoice.recipient_#{attribute}")].join(" ")
    end
  end
end
