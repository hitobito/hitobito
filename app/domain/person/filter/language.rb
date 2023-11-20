# frozen_string_literal: true

#  Copyright (c) 2012-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Language < Person::Filter::Base

  self.permitted_args = [:allowed_values]

  def apply(scope)
    scope.where(language: allowed_values)
  end

  def blank?
    allowed_values.blank?
  end

  def to_hash
    { allowed_values: allowed_values.map(&:to_s) }
  end

  def to_params
    { allowed_values: allowed_values }
  end

  def allowed_values
    @allowed_values ||= Array(args[:allowed_values]).reject(&:blank?).compact
  end

end
