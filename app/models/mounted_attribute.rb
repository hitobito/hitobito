# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MountedAttribute < ActiveRecord::Base
  belongs_to :entry, polymorphic: true

  serialize :value

  validates_by_schema

  def config
    @config ||= MountedAttr::ClassMethods
                .mounted_attr_registry
                .config_for(entry.class, key)
  end

  def casted_value
    case config.attr_type
    when :integer
      value.presence && Integer(value)
    else
      value
    end
  end

  def unset?
    case config.attr_type
    when :integer
      casted_value&.zero?
    else
      value.blank?
    end
  end
end
