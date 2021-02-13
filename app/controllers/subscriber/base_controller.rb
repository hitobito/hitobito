# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class BaseController < CrudController
    self.nesting = Group, MailingList

    decorates :group

    before_action :authorize!

    prepend_before_action :parent

    def create
      super(location: index_path)
    end

    private

    alias mailing_list parent

    def assign_attributes
      if subscriber_id
        entry.subscriber = subscriber
        entry.excluded = false
      end
    end

    def subscriber_id
      model_params && model_params[:subscriber_id].presence
    end

    def subscriber
      # implement in subclass
    end

    def replace_validation_errors
      default_base_errors.each do |attr, old, msg|
        if entry.errors[attr].first == old
          entry.errors.clear
          entry.errors.add(:base, msg)
        end
      end
    end

    def default_base_errors
      [[:subscriber_type, I18n.t("errors.messages.blank"),
        I18n.t("subscriber/base.blank", model_label: model_label)],
       [:subscriber_id, I18n.t("errors.messages.taken"),
        I18n.t("subscriber/base.taken", model_label: model_label)]]
    end

    def index_path
      group_mailing_list_subscriptions_path(@group, @mailing_list)
    end

    def authorize!
      if ["edit", "update"].include? action_name
        super(:update, entry)
      else
        super(:create, @subscription || @mailing_list.subscriptions.new)
      end
    end

    class << self
      def model_class
        Subscription
      end
    end
  end
end
