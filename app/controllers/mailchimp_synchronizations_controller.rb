class MailchimpSynchronizationsController < ApplicationController
  def create
    mailing_list = MailingList.find(params[:mailing_list_id])

    authorize!(:update, mailing_list)

    MailchimpSynchronizationJob.new(mailing_list.id).enqueue!
    #TODO: Properly localize flash message's text
    flash[:notice] = translate(:mailchimp_synchronization_enqueued, email: current_person.email)

    redirect_to(action: :index, controller: :subscriptions)
  end
end
