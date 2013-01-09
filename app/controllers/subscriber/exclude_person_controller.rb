# encoding: UTF-8
module Subscriber
  class ExcludePersonController < ApplicationController

    include PlainControllerSupport

    decorates :group

    respond_to :html
    helper_method :subscription, :mailing_list, :mailing_list_subscriptions_path
    before_filter :load_instance_variables

    def create
      assign_attributes

      if subscribed? && create_or_destroy
        redirect_to(mailing_list_subscriptions_path, notice: success_message(:unsubscribed))
      else
        subscription.errors.add(:base, error_message)
        respond_with(subscription, success: false)
      end
    end

    private

    def assign_attributes
      subscription.subscriber = person
      subscription.excluded = true
    end

    def subscribed?
      subscriber_id && mailing_list.subscribed?(person)
    end

    def create_or_destroy
       subscription.persisted? ? subscription.destroy : subscription.save
    end

    def mailing_list_subscriptions_path
      group_mailing_list_subscriptions_path(mailing_list.group, mailing_list)
    end

    def load_instance_variables
      subscription
      @mailing_list = mailing_list
      @group = mailing_list.group
    end

    def person
      @person ||= (subscriber_id && Person.find(subscriber_id))
    end

    def subscriber_id
      params[:subscription] && params[:subscription][:subscriber_id]
    end

    def extra_find_conditions
      { excluded: false }
    end

    def error_message
      person ? "#{person} ist kein Abonnent" : 'Person muss ausgewählt werden'
    end

  end
end
