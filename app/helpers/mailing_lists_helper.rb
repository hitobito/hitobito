module MailingListsHelper

  def button_toggle_subscription
    if entry.subscribable?
      if entry.subscribed?(current_user)
        action_button 'Abmelden', group_mailing_list_user_path(parent, entry), :minus, method: 'delete'
      else
        action_button 'Anmelden', group_mailing_list_user_path(parent, entry), :plus, method: 'post'
      end
    end


  end

end
