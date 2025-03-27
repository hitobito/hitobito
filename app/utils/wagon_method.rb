# frozen_string_literal: true

require "rubocop"
require "active_support/core_ext/array/access"
require "active_support/core_ext/enumerable"

class WagonMethod < RuboCop::Cop::Base
  MSG = "Patched in `%<location>s`"

  RESTRICT_ON_SEND = [:enabled?].freeze # optimization: don't call `on_send` unless
  # the method name is in this list
  # @!method sym_name(node)
  def_node_matcher :sym_name, "(sym $_name)"
  def_node_matcher :str_name, "(str $_name)"

  def wagon_hooks
    @wagon_hooks ||= YAML.load_file("patches.yml").index_by { |k, v| v.first }
  end

  def patches
    @patches ||= YAML.load_file(".patches/patches.yml").values
      .flat_map { |k, v| v[:patches].merge(key: key) }
      .group_by { |p| p[:method] }
  end

  def on_def(node)
    return if node.operator_method?

    # processed_source.file_path hat pfad zum aktuellen file
    if wagon_hooks.key?(node.method_name)
      patch = wagon_hooks[node.method_name]
      location = patch.second.second[%r{.*app/(.*)}, 1]
      register_offense(node, location)
    end
  end
  alias_method :on_defs, :on_def

  private

  def register_offense(node, location)
    message = format(MSG, location:)

    add_offense(node, message: message, severity: :info)
  end
end
