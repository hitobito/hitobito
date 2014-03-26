# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class UserController < ApplicationController

    before_action :authorize

    def create
      subscription.excluded = false
      if subscription.save
        redirect_to(mailing_list_path,
                    notice: translate(:success))
      else
        redirect_to(mailing_list_path,
                    alert: translate(:failure,
                                     errors: subscription.errors.full_messages.join(', ')))
      end
    end

    def destroy
      mailing_list.exclude_person(current_user)
      redirect_to(mailing_list_path, notice: translate(:unsubscribed))
    end

    private

    def authorize
      fail CanCan::AccessDenied unless mailing_list.subscribable?
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
