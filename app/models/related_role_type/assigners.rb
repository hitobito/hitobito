# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RelatedRoleType::Assigners

  # - has not to be encoded in URLs, ',' must be and thus generate a much longer string.
  ID_URL_SEPARATOR = '-'

  def role_types
    @role_types ||= related_role_types.collect(&:role_type)
  end

  def role_types=(types)
    @role_types = Array(types.presence)
    self.related_role_types = @role_types.collect { |t| RelatedRoleType.new(role_type: t) }
  end

  def role_type_ids
    @role_type_ids ||= related_role_types.collect { |r| r.role_class.id }
  end

  def role_type_ids=(ids)
    @role_type_ids = ids.is_a?(Array) ? ids : ids.to_s.split(ID_URL_SEPARATOR)
    @role_type_ids.collect!(&:to_i)
    self.role_types = Role.types_by_ids(@role_type_ids).collect(&:sti_name)
  end

  def role_type_ids_string
    role_type_ids.join(ID_URL_SEPARATOR)
  end
end
