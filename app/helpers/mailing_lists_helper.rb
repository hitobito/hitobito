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
      button_unsubscribe if entry.subscriptions.where(subscriber_id: current_user.id, subscriber_type: Person.sti_name).exists?
    else
      button_subscribe
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

  private

  # FIXME - appears redundant, subscriptions are also managed via Person::SubscriptionsController
  # subscribed? returns true (ie. subscribed via role) but without specific person subscription
  # Additionally, creating person subscription via list enforces abilities on list wheres creating via person enforces abilities on person
  def button_unsubscribe
    subscription = entry.subscriptions.where(subscriber_id: current_user.id, subscriber_type: Person.sti_name).first
    if subscription && can?(:destroy, subscription)
      action_button(t("mailing_list_decorator.unsubscribe"),
        group_mailing_list_subscription_path(@group, entry, subscription.id),
        :minus,
        method: "delete")
    end
  end

  def button_subscribe
    if can?(:create, Subscription.new(mailing_list: entry, subscriber: current_user))
      action_button(t("mailing_list_decorator.subscribe"),
        group_mailing_list_person_index_path(@group, entry, subscription: {subscriber_id: current_user.id}),
        :plus,
        method: "post")
    end
  end
end
