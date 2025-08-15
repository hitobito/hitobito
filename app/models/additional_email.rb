#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: additional_emails
#
#  id               :integer          not null, primary key
#  contactable_type :string           not null
#  email            :string           not null
#  invoices         :boolean          default(FALSE)
#  label            :string
#  mailings         :boolean          default(TRUE), not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
# rubocop:todo Layout/LineLength
#  idx_on_invoices_contactable_id_contactable_type_9f308c8a16      (invoices,contactable_id,contactable_type) WHERE (((contactable_type)::text = 'AdditionalEmail'::text) AND (invoices = true))
# rubocop:enable Layout/LineLength
#  index_additional_emails_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#

class AdditionalEmail < ActiveRecord::Base
  include ContactAccount
  include ValidatedEmail

  self.ignored_columns += [FullTextSearchable::SEARCH_COLUMN]

  self.value_attr = :email

  validates_by_schema

  # A dot at the end is invalid due to translation purpose
  validates :label, format: {without: /[.]$\z/}

  validates :invoices, uniqueness: {scope: [:contactable_id, :contactable_type], conditions: -> {
    where(invoices: true)
  }}, if: :invoices

  normalizes :email, with: ->(attribute) { attribute.downcase }

  class << self
    def predefined_labels
      Settings.additional_email.predefined_labels
    end
  end
end
