# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupsController < CrudController

  # Respective group attrs are added in corresponding instance method.
  self.permitted_attrs = Contactable::ACCESSIBLE_ATTRS.dup

  decorates :group, :groups, :contact

  before_render_show :active_sub_groups, if: -> { html_request? }
  before_render_form :load_contacts


  def index
    flash.keep if html_request?
    redirect_to group_path(Group.root.id, format: request.format.to_sym)
  end

  def show
    super do |format|
      format.json do
        render json: GroupSerializer.new(entry.decorate, controller: self)
      end
    end
  end

  def destroy
    super(location: entry.parent)
  end

  def deleted_subgroups
    load_sub_groups(entry.children.only_deleted)
  end

  def reactivate
    entry.update_column(:deleted_at, nil)

    flash[:notice] = translate(:reactivated, group: entry)
    redirect_to entry
  end

  def export_subgroups
    list = entry.self_and_descendants.
                 without_deleted.
                 order(:lft).
                 includes(:contact)
    csv = Export::Csv::Groups::List.export(list)
    send_data csv, type: :csv
  end

  private

  def build_entry
    type = model_params && model_params[:type]
    group = Group.find_group_type!(type).new
    group.parent_id = model_params[:parent_id]
    group
  end

  def permitted_attrs
    attrs = entry.class.used_attributes.dup
    attrs += self.class.permitted_attrs
    if entry.class.superior_attributes.present? && !can?(:modify_superior, entry)
      attrs -= entry.class.superior_attributes
    end
    attrs
  end

  def permitted_params
    p = model_params.dup
    p.delete(:type)
    p.delete(:parent_id)
    p.permit(permitted_attrs)
  end

  def load_contacts
    @contacts = entry.people.members.distinct.only_public_data.order_by_name
  end

  def active_sub_groups
    load_sub_groups(entry.children.without_deleted)
  end

  def load_sub_groups(scope)
    @sub_groups = Hash.new { |h, k| h[k] = [] }
    scope.order(:lft).each do |group|
      if can?(:show, group)
        label = group.layer ? group.class.label_plural : sub_groups_label
        @sub_groups[label] << group
      end
    end
    # move this entry to the end
    @sub_groups[sub_groups_label] = @sub_groups.delete(sub_groups_label)
  end


  def sub_groups_label
    @sub_groups_label ||= translate(:subgroups)
  end

end
