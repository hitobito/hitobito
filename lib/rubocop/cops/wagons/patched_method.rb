# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_swb.

require "rubocop"
require "active_support/core_ext/array/access"
require "active_support/core_ext/enumerable"
require "pry"
require_relative "../../../../app/utils/patches"

module RuboCop
  module Cop
    module Wagons
      class PatchedMethod < Base
        MSG = "Patched in `%<wagons>s`"

        RESTRICT_ON_SEND = [:enabled?].freeze # optimization: don't call `on_send` unless
        # the method name is in this list
        # @!method sym_name(node)
        def_node_matcher :sym_name, "(sym $_name)"
        def_node_matcher :str_name, "(str $_name)"

        def on_def(node)
          return if node.operator_method?

          patches = find_patches(node)
          register_offense(node, patches) if patches.present?
        end
        alias_method :on_defs, :on_def

        # tell rubocop to reuse cop instance, clear cache via on_investigation_end callback
        def self.support_multiple_source? = true

        private

        def register_offense(node, patches)
          message = format(MSG, wagons: patches.map(&:wagon).sort.uniq.join(", "))

          add_offense(node, message: message, severity: :info)
        end

        def find_patches(node) = @patches_by_method.fetch(node.method_name, [])

        # call whenever rubocop inspects a new file
        def on_new_investigation
          @basename = Pathname.new(processed_source.path).basename.to_s
          @patches_by_method = all_patches.fetch(@basename, []).group_by(&:method).to_h
        end

        def all_patches = @all_patches ||= load_patches

        def load_patches
          return {} unless File.exist?(Patches::ALL_PATCHES)
          YAML.load_file(Patches::ALL_PATCHES).map { |h|
            Patches::Patch.new(**h)
          }.group_by(&:basename)
        end
      end
    end
  end
end
