# encoding: UTF-8
module Subscriber
  class UserController < ApplicationController

    include PlainControllerSupport

    def create
      if subscription.persisted?
        subscription.excluded = false
      end

      subscription.save
      redirect_to(mailing_list_path, notice: success_message(:subscribed))
    end

    def destroy
      subscription.update_attribute(:excluded, true)
      redirect_to(mailing_list_path, notice: success_message(:unsubscribed))
    end

    private

    def custom_authorization
      raise CanCan::AccessDenied unless mailing_list.subscribable?
      super
    end

    def person
      current_user
    end

  end
end
