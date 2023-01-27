# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrailed
  extend ActiveSupport::Concern

  included do
    before_action :set_paper_trail_whodunnit
    before_action :set_paper_trail_controller_info
  end

  private

  def user_for_paper_trail
    return current_service_token.id if current_service_token

   session[:origin_user].presence || current_ability&.user&.id
  end

  def whodunnit_type_for_papertrail
    return current_service_token.class.sti_name if current_service_token

    current_ability&.user&.class&.sti_name
  end

  def info_for_paper_trail
    return {} unless whodunnit_type_for_papertrail.present?
    {
      whodunnit_type: whodunnit_type_for_papertrail
    }
  end
end
