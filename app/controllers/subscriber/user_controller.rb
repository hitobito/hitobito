# encoding: UTF-8
module Subscriber
  class UserController < ApplicationController

    before_filter :authorize
      
    def create
      subscription.excluded = false
      subscription.save
      redirect_to(mailing_list_path, notice: "Du wurdest dem Abo erfolgreich hinzugefügt")
    end

    def destroy
      mailing_list.exclude_person(current_user)
      redirect_to(mailing_list_path, notice: "Du wurdest erfolgreich vom Abo entfernt")
    end

    private

    def authorize
      raise CanCan::AccessDenied unless mailing_list.subscribable?
      authorize!(:update, subscription)
    end
    
    def subscription
      @subscription ||= find_subscription || build_subscription
    end

    def build_subscription
      subscription = mailing_list.subscriptions.new
      subscription.subscriber = current_user
      subscription
    end

    def find_subscription
      mailing_list.subscriptions.where(subscriber_id: current_user.id, 
                                       subscriber_type: Person.sti_name).
                                 first
    end

    def mailing_list
      @mailing_list ||= MailingList.find(params[:mailing_list_id])
    end

    def mailing_list_path
      group_mailing_list_path(group_id: mailing_list.group.id, id: mailing_list.id)
    end

  end
end
