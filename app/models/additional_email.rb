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
#  label            :string
#  mailings         :boolean          default(TRUE), not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  additional_emails_search_column_gin_idx                         (search_column) USING gin
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

  normalizes :email, with: ->(attribute) { attribute.downcase }

  class << self
    def predefined_labels
      Settings.additional_email.predefined_labels
    end
  end
end
