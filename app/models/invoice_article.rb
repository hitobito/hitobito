# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoice_articles
#
#  id          :integer          not null, primary key
#  number      :string(255)
#  name        :string(255)      not null
#  description :string(255)
#  category    :string(255)
#  net_price   :decimal(12, 2)
#  vat_rate    :decimal(5, 2)
#  cost_center :string(255)
#  account     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class InvoiceArticle < ActiveRecord::Base

  def self.categories
    pluck(:category).uniq
  end

  def self.cost_centers
    pluck(:cost_center).uniq
  end

  def self.accounts
    pluck(:account).uniq
  end

  def to_s
    [number, name].compact.join(' - ')
  end

end
