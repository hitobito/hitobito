require 'digest/md5'

class MailchimpExportsController < ApplicationController
  #TODO
  skip_authorization_check

  def new
    #TODO affect UI behavior via js.erb partial
    MailchimpExportJob.new(permitted_params[:group_id]).enqueue!
  end

  private

  def permitted_params
    #TODO
    params
  end
end
