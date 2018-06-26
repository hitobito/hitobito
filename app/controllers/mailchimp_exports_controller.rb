class MailchimpExportsController < ApplicationController
  skip_authorization_check

  def new
    @group = Group.find(params[:group_id])
    @people = @group.people
  end

  private

  def permitted_params
    #TODO
  end
end
