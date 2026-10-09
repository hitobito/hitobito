# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class BlocklistEntriesController < SimpleCrudController
  private

  def permitted_attrs
    [:person_id, manual_person_attributes: Person::BlocklistDetector.hash_attrs]
  end

  def list_entries
    super.includes(:creator).order(created_at: :desc).page(params[:page])
  end

  def assign_attributes
    super
    entry.creator = current_user
  end

  def set_success_notice
    flash[:notice] = notice_with_link_to_person if action_name == "create" && showable_person?
    super
  end

  def showable_person?
    entry.person && can?(:show, entry.person)
  end

  def notice_with_link_to_person
    helpers.t("blocklist_entries.create.flash.success_with_person_html",
      person: helpers.link_to(entry.person.to_s, person_path(entry.person)))
  end
end
