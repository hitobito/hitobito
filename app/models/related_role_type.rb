#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
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
