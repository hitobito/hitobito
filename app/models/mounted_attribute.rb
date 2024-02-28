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

  def value=(new_value)
    value = with_default(cast_value(new_value))
    write_attribute(:value, value)
  end

  def value
    with_default(read_attribute(:value))
  end

  private

  def cast_value(value)
    config.type.cast(value)
  end

  def with_default(value)
    return config.default if
      !config.default.nil? && (value.nil? || value.try(:empty?) || value.try(:zero?))

    value
  end
end
