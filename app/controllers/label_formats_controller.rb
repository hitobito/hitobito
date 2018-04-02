# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class LabelFormatsController < SimpleCrudController

  self.permitted_attrs = [:name, :page_size, :landscape, :font_size, :width, :height,
                          :padding_top, :padding_left, :count_horizontal, :count_vertical,
                          :nickname, :pp_post]

  self.sort_mappings = { name: 'label_format_translations.name',
                         dimensions: %w(count_horizontal count_vertical) }

  before_render_index :global_entries

  private

  def build_entry
    super.tap do |entry|
      entry.person_id = current_user.id if current_user && !manage_global?
    end
  end

  def manage_global?
    params[:global] == 'true' && can?(:manage_global, LabelFormat)
  end

  def list_entries
    super.list.where(person_id: current_user.id)
  end

  def global_entries
    @global_entries = LabelFormat.list.where(person_id: nil)
    if sorting?
      @global_entries = @global_entries.reorder(sort_expression)
    end
  end

end
