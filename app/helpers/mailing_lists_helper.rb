# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingListsHelper

  def button_toggle_subscription
    if entry.subscribable?
      if entry.subscribed?(current_user)
        action_button 'Abmelden', group_mailing_list_user_path(@group, entry), :minus, method: 'delete'
      else
        action_button 'Anmelden', group_mailing_list_user_path(@group, entry), :plus, method: 'post'
      end
    end
  end

end
