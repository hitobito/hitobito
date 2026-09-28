#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # Configuration for attribute-level permissions.
  # Records which attributes are permitted or excluded for a given
  # permission, action and constraint.
  #
  # +kind+ is either :permit (allowlist) or :except (denylist).
  #
  # For +:permit+, a +can+ rule scoped to the listed attributes is generated.
  # For +:except+, a +cannot+ rule scoped to the listed attributes is generated
  # (paired with a broad +can+ rule registered separately).
  class AttributeConfig
    attr_reader :permission, :subject_class, :action, :ability_class,
      :constraint, :attrs, :kind

    def initialize(permission, subject_class, action, ability_class, constraint, attrs,
      kind = :permit)
      @permission = permission
      @subject_class = subject_class
      @action = action
      @ability_class = ability_class
      @constraint = constraint
      @attrs = Array(attrs)
      @kind = kind
    end
  end
end
