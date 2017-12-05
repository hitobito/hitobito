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
#  sequence_number     :integer          default(1), not null
#  due_days            :integer          default(30), not null
#  group_id            :integer          not null
#  contact_id          :integer
#  page_size           :integer          default(15)
#  address             :text(65535)
#  payment_information :text(65535)
#

class InvoiceConfig < ActiveRecord::Base
  belongs_to :group, class_name: 'Group'
  belongs_to :contact, class_name: 'Person'

  validates :group_id, uniqueness: true

  validates_by_schema

  def to_s
    "#{group.name} - Invoice Config" # TODO: determine proper string representation
  end

end
