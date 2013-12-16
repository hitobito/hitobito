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
#  relation_id   :integer
#  role_type     :string(255)      not null
#  relation_type :string(255)
#

class RelatedRoleType < ActiveRecord::Base

  belongs_to :relation, polymorphic: true

  attr_accessible :role_type

  validates :role_type, inclusion: { in: lambda { |i| Role.all_types.collect(&:sti_name) } }

  def to_s
    role_class.label_long
  end

  def role_class
    role_type.constantize
  end

end
