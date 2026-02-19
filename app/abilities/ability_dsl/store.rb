#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  class Store
    def register(*classes)
      ability_classes.concat(classes)
    end

    def configs_for_permissions(permissions)
      permissions_with_any = permissions + [:any]
      configs.values.each do |c|
        yield c if permissions_with_any.include?(c.permission)
      end
    end

    def general_constraints(subject_class, action)
      [config(Recorder::General::PERMISSION, subject_class, action),
        config(Recorder::General::PERMISSION, subject_class, Recorder::General::ALL_ACTION)]
        .compact
    end

    def class_side_constraints
      configs.values.each do |c|
        yield c if c.permission == Recorder::ClassSide::PERMISSION
      end
    end

    def configs
      load # ensure store is loaded
      @configs
    end

    def load
      return if @loaded

      @configs = {}
      @attribute_configs = {}
      ability_classes.each do |ability_class|
        Recorder.new(self, ability_class).run
      end
      @loaded = true
      @configs
    end

    # add a config to the store.
    # configs with the same permission, subject_class and action are overwritten.
    def add(config)
      @configs[[config.permission, config.subject_class, config.action]] = config
    end

    # Add an attribute-level permission config.
    # Configs with the same permission, subject_class, action, and constraint are
    # overwritten (last registered wins, allowing wagon overrides).
    def add_attribute_config(config)
      @attribute_configs[[config.permission, config.subject_class, config.action]] = config
    end

    def config(permission, subject_class, action)
      configs[[permission, subject_class, action]]
    end

    # Find the attribute config matching a regular config's identity.
    def attribute_config(permission, subject_class, action)
      load # ensure store is loaded
      (@attribute_configs || {})[[permission, subject_class, action]]
    end

    def ability_classes
      @ability_classes ||= []
    end

    def only_manager_inheritable
      filtered_configs = configs.select { |_, config| config.options[:include_manageds] }
      AbilityDsl::Store.new.tap do |clone|
        clone.instance_variable_set(:@ability_classes, ability_classes)
        clone.instance_variable_set(:@configs, filtered_configs)
        clone.instance_variable_set(:@attribute_configs, @attribute_configs)
      end
    end
  end
end
