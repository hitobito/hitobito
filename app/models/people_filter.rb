# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  group_id   :integer
#  group_type :string(255)
#

class PeopleFilter < ActiveRecord::Base

  include RelatedRoleType::Assigners

  attr_accessible :name, :role_types, :role_type_ids


  belongs_to :group

  has_many :related_role_types, as: :relation, dependent: :destroy

  validates :name, uniqueness: { scope: [:group_id, :group_type] }


  default_scope order(:name).includes(:related_role_types)

  def to_s
    name
  end

  class << self
    def for_group(group)
      where('group_id = ? OR group_type = ? OR (group_id IS NULL AND group_type IS NULL)', group.id, group.type)
    end
  end

end
