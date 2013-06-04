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