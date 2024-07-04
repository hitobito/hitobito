# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payees
#
#  id             :bigint           not null, primary key
#  person_address :text(65535)
#  person_name    :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  payment_id     :bigint           not null
#  person_id      :bigint
#
# Indexes
#
#  index_payees_on_payment_id  (payment_id)
#  index_payees_on_person_id   (person_id)
#

class Payee < ActiveRecord::Base
  belongs_to :payment
  belongs_to :person, optional: true
end
