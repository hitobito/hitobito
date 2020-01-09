# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: people_filters
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  group_id     :integer
#  group_type   :string(255)
#  filter_chain :text(65535)
#  range        :string(255)      default("deep")
#  created_at   :datetime
#  updated_at   :datetime
#

class PeopleFilter < ActiveRecord::Base

  RANGES = %w(deep layer group).freeze

  serialize :filter_chain, Person::Filter::Chain

  belongs_to :group

  validates_by_schema
  validates :name, uniqueness: { scope: [:group_id, :group_type], case_sensitive: false }
  validates :range, inclusion: { in: RANGES }

  scope :list, -> { order(:name) }

  def to_params
    { name: name, range: range, filters: filter_chain.to_params }
  end

  def to_s(_format = :default)
    name
  end

  def filter_chain=(value)
    if value.is_a?(Hash)
      super(Person::Filter::Chain.new(value))
    else
      super
    end
  end

  class << self
    def for_group(group)
      includes(:group)
        .where('group_id = ? OR group_type = ? OR ' \
               '(group_id IS NULL AND group_type IS NULL)',
               group.id,
               group.type)
    end
  end

end
