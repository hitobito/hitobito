# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Builder for SQL OR conditions
class OrCondition
    
  def initialize
    @condition = [""]
  end
  
  def or(clause, *args)
    @condition.first << " OR " if present?
    @condition.first << "(#{clause})"
    @condition.push(*args)
  end
  
  def to_a
    @condition
  end
  
  def blank?
    @condition.first.blank?
  end
  
end