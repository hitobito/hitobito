#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  class Config
    attr_reader :permission, :subject_class, :action, :ability_class, :constraint

    def initialize(permission, subject_class, action, ability_class, constraint)
      @permission = permission
      @subject_class = subject_class
      @action = action
      @ability_class = ability_class
      @constraint = constraint
    end
  end
end
