# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MountedAttributes
  class Store
    def initialize
      @configs = []
    end

    def register(target_class, attr_name, attr_type, options)
      config = MountedAttributes::Config.new(target_class, attr_name, attr_type, options)
      @configs << config
      config
    end

    def config_for(target_class, attr_name)
      @configs.find do |config|
        config.target_class == target_class && config.attr_name == attr_name.to_sym
      end
    end
  end
end
