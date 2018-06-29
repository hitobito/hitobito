class MailchimpSynchronizationsController < ApplicationController
  #TODO
  skip_authorization_check
  respond_to :js

  def create
    #TODO affect UI behavior via js.erb partial
    MailchimpSynchronizationJob.new(permitted_params[:group_id]).enqueue!
  end

  private

  def permitted_params
    #TODO
    params
  end
end
