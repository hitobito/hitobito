module AbilityDsl
  class Config

    attr_reader :ability_class

    def initialize(ability_class)
      @ability_class = ability_class
    end

    def define
      ability_class.configs.each do |subject_class, permission_blocks|
        @subject_class = subject_class
        permission_blocks.each do |block|
          instance_eval(&block)
        end
      end
    end

    def permission(permission)
      # TODO validate permission
      @permission = permission
      self
    end

    def may(*actions)
      @actions = actions
      self
    end

    def method_missing(name, *args)
      if args.blank? && ability_class.condition_methods.include?(name)
        AbilityNew.add_config(@permission, @subject_class, @actions, name)
        nil
      else
        super
      end
    end
  end
end