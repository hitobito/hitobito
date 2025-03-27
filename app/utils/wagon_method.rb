# frozen_string_literal: true

require "rubocop"
require "active_support/core_ext/array/access"
require "active_support/core_ext/enumerable"
require "pry"
require_relative "patches"

class WagonMethod < RuboCop::Cop::Base
  MSG = "Patched in `%<location>s`"

  RESTRICT_ON_SEND = [:enabled?].freeze # optimization: don't call `on_send` unless
  # the method name is in this list
  # @!method sym_name(node)
  def_node_matcher :sym_name, "(sym $_name)"
  def_node_matcher :str_name, "(str $_name)"

  def on_def(node)
    return if node.operator_method?

    # processed_source.file_path hat pfad zum aktuellen file
    if patches_by_method.key?(node.method_name)
      wagons = patches_by_method[node.method_name].group_by(&:basename)[processed_source_basename].map(&:wagon).sort.uniq

      register_offense(node, wagons.join(", "))
    end
  end
  alias_method :on_defs, :on_def

  private

  def processed_source_basename
    Pathname.new(processed_source.path).basename.to_s
  end

  def register_offense(node, location)
    message = format(MSG, location:)

    add_offense(node, message: message, severity: :info)
  end

  def load_patches
    YAML.load_file(Patches::ALL_PATCHES).map { |h| Patches::Patch.new(**h) }
  end

  def patches_by_method
    @patches_by_method ||= load_patches.group_by(&:method)
  end
end
