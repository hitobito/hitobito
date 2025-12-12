#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
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
