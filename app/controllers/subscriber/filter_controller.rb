# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class FilterController < BaseController

    skip_authorize_resource # must be in leaf class

    def update
      assign_attributes
      if mailing_list.save
        redirect_to(subscriptions_path, notice: translate(:success))
      else
        redirect_to(subscriptions_path,alert: translate(:failure,
                                       errors: mailing_list.errors.full_messages.join(', ')))
      end
    end

    private

    def assign_attributes
      filter_params = params[:filters]
      mailing_list.filter_chain = filter_params.except(:host).to_unsafe_hash if filter_params
    end

    def entry 
      mailing_list 
    end

    # def subscription
    #   @subscription ||= find_subscription || build_subscription
    # end

    # def find_subscription
    #   mailing_list.subscriptions.where(subscriber_id: current_user.id,
    #                                    subscriber_type: Person.sti_name).
    #                              first
    # end

    def mailing_list
      @mailing_list ||= MailingList.find(params[:mailing_list_id])
    end

    def subscriptions_path
      group_mailing_list_subscriptions_path(group_id: mailing_list.group.id, id: mailing_list.id)
    end

  end
end
