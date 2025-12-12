#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class InvoiceArticle < ActiveRecord::Base
  belongs_to :group

  validates :name, presence: true, uniqueness: {scope: :group_id, case_sensitive: false}
  validates :number, presence: true, uniqueness: {scope: :group_id, case_sensitive: false}
  validates :unit_cost, money: true, allow_nil: true

  validates_by_schema

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
    [number, name].compact.join(" - ")
  end
end
