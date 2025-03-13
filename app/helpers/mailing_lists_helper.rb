#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingListsHelper
  def format_mailing_list_name(mailing_list)
    content_tag(:strong) do
      if can?(:update, mailing_list)
        link_to(
          mailing_list.name,
          group_mailing_list_messages_path(mailing_list.group, mailing_list.id)
        )
      else
        mailing_list.name
      end
    end
  end

  def mailing_list_name_with_group_name(mailing_list)
    content = []
    content << "#{mailing_list.group.name} >" unless mailing_list.group.layer?
    content << format_mailing_list_name(mailing_list)

    content_tag(:div, safe_join(content.compact, " "))
  end

  def format_mailing_list_preferred_labels(mailing_list)
    safe_join mailing_list.preferred_labels.sort, ", "
  end

  def button_toggle_subscription
    if entry.subscribed?(current_user)
      button_unsubscribe(entry) if can?(:destroy, Subscription.new(mailing_list: entry, subscriber: current_user))
    elsif can?(:create, Subscription.new(mailing_list: entry, subscriber: current_user))
      button_subscribe(entry)
    end
  end

  def format_mailchimp_sync(mailing_list)
    if mailing_list.mailchimp_result
      last_synced_at = mailing_list.mailchimp_last_synced_at
      state, badge_class = mailing_list.mailchimp_result.badge_info
      text = I18n.t("activerecord.attributes.mailing_list.mailchimp_states.#{state}")
      exception = mailing_list.mailchimp_result.data[:exception]
      content = []
      content << content_tag(:span, I18n.l(last_synced_at, format: :short)) if last_synced_at
      content << content_tag(:span, badge(text, badge_class), title: exception)
      content_tag(:div, safe_join(content.compact, " "))
    end
  end

  def button_unsubscribe(list, person: current_user, icons: true)
    label = t("mailing_list_decorator.unsubscribe")
    action_button(label,
      group_person_subscription_path(list.group, person, id: list.id),
      icons ? :minus : nil,
      method: "delete",
      data: {disable_with: icons ? "#{icon(:minus)} #{label}" : label})
  end

  def button_subscribe(list, person: current_user, icons: true)
    label = t("mailing_list_decorator.subscribe")
    action_button(label,
      group_person_subscriptions_path(list.group, person, id: list.id),
      icons ? :plus : nil,
      method: "post",
      data: {disable_with: icons ? "#{icon(:plus)} #{label}" : label})
  end
end
