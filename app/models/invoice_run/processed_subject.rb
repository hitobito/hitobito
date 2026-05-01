# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoice_run_processed_subjects
#
#  id               :bigint           not null, primary key
#  subject_type     :string           not null
#  item_id          :bigint           not null
#  subject_id       :bigint           not null
#  template_item_id :bigint           not null
#
# Indexes
#
#  index_invoice_run_processed_subjects_on_item_id           (item_id)
#  index_invoice_run_processed_subjects_on_template_item_id  (template_item_id)
#  index_processed_subjects                                  (subject_type,subject_id,template_item_id,item_id)
#  index_unique_processed_subjects                           (subject_type,subject_id,template_item_id) UNIQUE
#
class InvoiceRun::ProcessedSubject < ActiveRecord::Base
  self.table_name = "invoice_run_processed_subjects"

  belongs_to :item, class_name: "InvoiceItem"
end
