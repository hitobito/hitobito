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

  helper_method :personal_entries

  def create
    super
    if normal_user? || (admin_user? && current_user_set?)
      entry.update(user_id: current_user.id)
    end
  end

  private

  def normal_user?
    !admin_user?
  end

  def admin_user?
    can?(:create_global, entry)
  end

  def current_user_set?
    !params[:current_user].blank?
  end

  def list_entries
    super.list
  end

  def entries
    LabelFormat.where(user_id: nil)
  end

  def personal_entries
    LabelFormat.where(user_id: current_user.id)
  end

end
