# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Tag < Person::Filter::Base
  self.permitted_args = [:names]

  def apply(scope)
    scope.joins(:tags).where(tags_condition).distinct
  end

  def blank?
    names.blank?
  end

  def to_hash
    {names: names}
  end

  def to_params
    {names: names}
  end

  private

  def tags_condition
    {tags: {name: names}}
  end

  def names
    @names ||= Array(args[:names]).reject(&:blank?).compact
  end
end
