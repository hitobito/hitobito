# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RelatedRoleType::Assigners
  def role_types
    @role_types ||= related_role_types.collect(&:role_type)
  end
  
  def role_types=(types)
    @role_types = Array(types.presence)
    self.related_role_types = @role_types.collect {|t| RelatedRoleType.new(role_type: t) }
  end
end