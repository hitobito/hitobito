require 'digest/md5'

class MailchimpExportsController < ApplicationController
  #TODO
  skip_authorization_check

  def new
    MailchimpExportJob.new(permitted_params[:group_id]).enqueue!
  end

  private

  def permitted_params
    params
  end
end
