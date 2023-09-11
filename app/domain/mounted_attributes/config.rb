# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MountedAttributes
  class Config
    attr_reader :target_class, :attr_name, :attr_type, :options,
                :null, :enum, :default

    def initialize(target_class, attr_name, attr_type, options)
      @target_class = target_class
      @attr_name = attr_name
      @attr_type = attr_type

      initialize_options(options)
    end

    def initialize_options(options)
      @options = options

      @null = options[:null]
      @null ||= true
      @enum = options[:enum]
      @default = options[:default]
    end

    def mounted_attribute_class
      @mounted_attribute_class ||= if attr_type == :picture
                                     MountedAttributeAttached
                                   else
                                     MountedAttribute
                                   end
    end
  end
end
