# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MountedAttributes
  class Config
    attr_reader :target_class, :attr_name, :attr_type, :type,
                :options, :null, :enum, :default, :category

    def initialize(target_class, attr_name, attr_type, null: true, **options)
      raise ArgumentError, 'null must be true or false' unless [true, false].include?(null)

      @target_class = target_class
      @attr_name = attr_name
      @attr_type = attr_type
      @type = ActiveModel::Type.lookup(attr_type)
      @null = null

      initialize_options(options)
    end

    private

    def initialize_options(options)
      @options = options

      @enum = options[:enum]
      @default = type.cast(options[:default])
      @category = options[:category]
    end

  end
end
