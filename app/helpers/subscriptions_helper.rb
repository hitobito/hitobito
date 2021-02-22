module SubscriptionsHelper
  def dropdown_subscriptions_export
    path = if @mailing_list.mailchimp?
      group_mailing_list_mailchimp_synchronizations_path(group_id: @group.id,
                                                         mailing_list_id: @mailing_list.id)
    end

    Dropdown::PeopleExport.new(self, current_user, params,
      details: false,
      emails: true,
      labels: true,
      households: true,
      mailchimp_synchronization_path: path).to_s
  end
end
