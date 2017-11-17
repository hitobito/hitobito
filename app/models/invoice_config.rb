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
