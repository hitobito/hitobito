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
    case current_ability
    when Ability
      origin_user_id = session[:origin_user]
      origin_user_id ? origin_user_id : super
    when TokenAbility
      current_ability.token.id
    when DoorkeeperTokenAbility
      current_ability.user.id
    end
  end

  def info_for_paper_trail
    return super unless current_ability.is_a?(TokenAbility)

    { whodunnit_type: current_ability.token.class.sti_name }
  end
end
