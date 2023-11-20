# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2012-2023, Pfadibewegung Schweiz. This file is part of
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
      mailing_list.filter_chain = params[:filters]&.except(:host)&.to_unsafe_hash
    end

    def entry
      mailing_list
    end

    def mailing_list
      @mailing_list ||= MailingList.find(params[:mailing_list_id])
    end

    def subscriptions_path
      group_mailing_list_subscriptions_path(group_id: mailing_list.group.id, id: mailing_list.id)
    end

  end
end
