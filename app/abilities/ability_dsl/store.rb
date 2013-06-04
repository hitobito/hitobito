module AbilityDsl
  class Store

    def register(*classes)
      ability_classes.concat(classes)
    end

    def configs_for_permissions(permissions)
      permissions_with_any = permissions + [:any]
      configs.each do |key, c|
        yield c if permissions_with_any.include?(c.permission)
      end
    end

    def general_constraints(subject_class, action)
      [config(Recorder::General::Permission, subject_class, action),
       config(Recorder::General::Permission, subject_class, Recorder::General::AllAction)].
      compact
    end


    def configs
      @configs ||= load
    end

    def load
      @configs = {}
      ability_classes.each do |ability_class|
        Recorder.new(self, ability_class).run
      end
      @configs
    end

    # add a config to the store.
    # configs with the same permission, subject_class and action are overwritten.
    def add(config)
      @configs[[config.permission, config.subject_class, config.action]] = config
    end

    def config(permission, subject_class, action)
      configs[[permission, subject_class, action]]
    end

    def ability_classes
      @ability_classes ||= []
    end

  end
end