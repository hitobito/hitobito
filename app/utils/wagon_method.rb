# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_swb.

require "rubocop"
require "active_support/core_ext/array/access"
require "active_support/core_ext/enumerable"
require "pry"
require_relative "patches"

class WagonMethod < RuboCop::Cop::Base
  MSG = "Patched in `%<wagons>s`"

  RESTRICT_ON_SEND = [:enabled?].freeze # optimization: don't call `on_send` unless
  # the method name is in this list
  # @!method sym_name(node)
  def_node_matcher :sym_name, "(sym $_name)"
  def_node_matcher :str_name, "(str $_name)"

  def on_def(node)
    return if node.operator_method?

    wagon_patches = find_patches(node.method_name).uniq
    register_offense(node, wagon_patches) if wagon_patches.present?
  end
  alias_method :on_defs, :on_def

  private

  def find_patches(method_name)
    patches = patches_by_method.fetch(method_name, [])
    patches.select { |patch| patch.basename == processed_source_basename }
  end

  def register_offense(node, patches)
    message = format(MSG, wagons: patches.map(&:wagon).sort.uniq.join(", "))

    # NOTE - autocorrect is not really an option
    add_offense(node, message: message, severity: :info)
  end

  # TODO - constants are not loaded, will that be enough
  def processed_source_basename
    Pathname.new(processed_source.path).basename.to_s
  end

  def load_patches
    YAML.load_file(Patches::ALL_PATCHES).map { |h| Patches::Patch.new(**h) }
  end

  def patches_by_method
    @patches_by_method ||= load_patches.group_by(&:method)
  end
end
