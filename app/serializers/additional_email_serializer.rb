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
#  additional_emails_search_column_gin_idx                         (search_column) USING gin
#  idx_on_invoices_contactable_id_contactable_type_9f308c8a16      (invoices,contactable_id,contactable_type) WHERE (((contactable_type)::text = 'AdditionalEmail'::text) AND (invoices = true))
#  index_additional_emails_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AdditionalEmailSerializer < ContactAccountSerializer
  schema do
    contact_properties

    map_properties :mailings
  end
end
