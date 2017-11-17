# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoice_configs
#
#  id                  :integer          not null, primary key
#  group_id            :integer          not null
#  contact_id          :integer
#  sequence_number     :integer          default(1), not null
#  due_days            :integer          default(30), not null
#  address             :text
#  payment_information :text
#

class InvoiceConfig < ActiveRecord::Base
  belongs_to :group, class_name: 'Group'
  belongs_to :contact, class_name: 'Person'

  validates :group_id, uniqueness: true

  validates_by_schema
end
