# encoding: utf-8

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
       config(Recorder::General::PERMISSION, subject_class, Recorder::General::ALL_ACTION)].
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
