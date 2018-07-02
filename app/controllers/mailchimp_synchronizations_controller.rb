class MailchimpSynchronizationsController < ApplicationController
  #TODO
  skip_authorization_check

  def create
    respond_to do |format|
      format.js do
        MailchimpSynchronizationJob.new(permitted_params[:mailing_list_id]).enqueue!
        flash[:notice] = translate(:mailchimp_synchronization_enqueued, email: current_person.email)
        #TODO: Properly localize flash message's text
        redirect_to(action: :index, controller: :subscriptions)
      end
    end
  end

  private

  def permitted_params
    #TODO
    params
  end
end
