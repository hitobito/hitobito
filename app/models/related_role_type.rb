# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: related_role_types
#
#  id            :integer          not null, primary key
#  relation_type :string(255)
#  role_type     :string(255)      not null
#  relation_id   :integer
#
# Indexes
#
#  index_related_role_types_on_relation_id_and_relation_type  (relation_id,relation_type)
#  index_related_role_types_on_role_type                      (role_type)
#

class RelatedRoleType < ActiveRecord::Base
  belongs_to :relation, polymorphic: true

  validates_by_schema
  validates :role_type, inclusion: {in: ->(_) { Role.all_types.collect(&:sti_name) }}

  def to_s(_format = :default)
    role_class.label_long
  end

  def role_class
    role_type.constantize
  end

  def group_class
    role_class.model_name.to_s.deconstantize.constantize
  end
end
