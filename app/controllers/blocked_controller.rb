# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
#
# Can also be used for dynamic error pages if those static files do not exist.
class BlockedController < ApplicationController
  layout 'application'

  skip_authorization_check
  skip_before_action :reject_blocked_person!

  def index
    return redirect_to root_path unless current_user.blocked?

    respond_to do |format|
      format.html do
        load_info_texts
        render 'index', status: 403
      end
      format.json do
        render 'index', status: 403
      end
    end

  end

  private

  def get_content(key, placeholders = nil)
    content = CustomContent.get(key)
    placeholders ||= {
      'person-name' => h(current_person.full_name)
    }
    content.body_with_values(placeholders).to_s.html_safe
  end

  # rubocop:disable Layout/LineLength
  def load_info_texts
    @blocked_person_title_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_TITLE)
    @blocked_person_situation_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_SITUATION)
    @blocked_person_solution_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_SOLUTION)
    if Person::BlockService.inactivity_block_interval_placeholders.values.all?(&:present?)
      @blocked_person_interval_text = get_content(Person::SecurityToolsController::BLOCKED_PERSON_INTERVAL,
                                                  Person::BlockService.inactivity_block_interval_placeholders)
    end
  end
  # rubocop:enable Layout/LineLength
end
