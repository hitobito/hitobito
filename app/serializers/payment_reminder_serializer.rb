# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: payment_reminders
#
#  id         :integer          not null, primary key
#  due_at     :date             not null
#  level      :integer
#  text       :string(255)
#  title      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  invoice_id :integer          not null
#
# Indexes
#
#  index_payment_reminders_on_invoice_id  (invoice_id)
#

class PaymentReminderSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :due_at,
      :created_at,
      :updated_at,
      :title,
      :text,
      :level
  end
end
