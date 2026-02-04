# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module WagonHelper
  # When rendering a core partial, we want to use the core partial as the primary source when
  # loading partials. So it does not get overridden by any other wagon partial.
  # To prevent issues with render_extensions after loading core partials we still
  # load all view_paths but in a different order. Since render_extensions only renders
  # wagon partials, because the path expects to have an underscore at the end of a
  # partial name with the specific wagon name, we can put the core first.
  def render_core_partial(partial_name, locals = {})
    core_view_path = Rails.root.join("app", "views")

    with_root_view_path(core_view_path) do
      render(partial_name, locals)
    end
  end

  private

  # When rendering partials the order of the PathSet decides what partials are rendered in
  # what order to overwrite eachother. This method is used to put a custom path as the
  # highest/first path for the generation of partials
  def with_root_view_path(path)
    original_view_paths = view_paths.dup
    ordered_view_paths = view_paths.dup.to_a.map(&:path).prepend(path.to_s)

    view_paths = ActionView::PathSet.new(ordered_view_paths)
    lookup_context.instance_variable_set(:@view_paths, view_paths)
    begin
      yield
    ensure
      lookup_context.instance_variable_set(:@view_paths, original_view_paths)
    end
  end
end
