# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class LabelFormatsController < SimpleCrudController

  self.permitted_attrs = [:name, :page_size, :landscape, :font_size, :width, :height,
                          :padding_top, :padding_left, :count_horizontal, :count_vertical]

  self.sort_mappings = { name: 'label_format_translations.name',
                         dimensions: %w(count_horizontal count_vertical) }

  before_render_index :global_entries

  private

  def assign_attributes
    super
    if entry.new_record? && !manage_global?
      entry.user_id = current_user.id
    end
  end

  def manage_global?
    params[:global] == 'true' && can?(:manage_global, entry)
  end

  def list_entries
    super.list.where(user_id: current_user.id)
  end

  def global_entries
    @global_entries = LabelFormat.list.where(user_id: nil)
    if sorting?
       @global_entries = @global_entries.reorder(sort_expression)
    end
  end

end
