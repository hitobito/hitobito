# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module WagonHelper
  def render_core_partial(partial_name, locals = {})
    core_view_path = Rails.root.join("app", "views")

    prefixes = partial_name.include?("/") ? [] : lookup_context.prefixes
    template = nil
    with_view_path(core_view_path) do
      template = lookup_context.find_template(partial_name, prefixes, true, locals.keys, [])
    end

    render(template: template, locals: locals)
  end

  private

  def with_view_path(path)
    original_view_paths = view_paths.dup

    view_paths = ActionView::PathSet.new([path])
    lookup_context.instance_variable_set(:@view_paths, view_paths)
    begin
      yield
    ensure
      lookup_context.instance_variable_set(:@view_paths, original_view_paths)
    end
  end
end
