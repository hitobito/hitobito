# frozen_string_literal: true

# == Schema Information
#
# Table name: invoice_item_roles
#
#  id              :bigint           not null, primary key
#  year            :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  invoice_item_id :bigint
#  role_id         :bigint
#
# Indexes
#
#  index_invoice_item_roles_on_invoice_item_id   (invoice_item_id)
#  index_invoice_item_roles_on_role_id           (role_id)
#  index_invoice_item_roles_on_role_id_and_year  (role_id,year) UNIQUE
#

class InvoiceItemRole < ActiveRecord::Base
  belongs_to :role
  belongs_to :invoice_item
end
