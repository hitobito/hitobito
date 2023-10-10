# frozen_string_literal: true

#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class SubscriberListsController < SimpleCrudController
    helper_method :group

    respond_to :js, only: [:new]
    respond_to :json, only: [:typeahead]
    self.search_columns = ['mailing_lists.name', 'mailing_lists.mail_name']

    skip_authorization_check
    skip_authorize_resource

    def new
      @people_ids = params[:ids]
    end

    def create
      authorize!(:create, mailing_list.subscriptions.new)

      new_subscriptions = build_new_subscriptions
      ActiveRecord::Base.transaction do
        new_subscriptions.map(&:save).all?(&:present?)
      end

      redirect_to(group_people_path(group),
                  notice: flash_message(:success, count: new_subscriptions.count))
    end

    def typeahead
      entries = MailingList.joins(:group)
                           .includes(:group)
                           .where(group: group.local_hierarchy)
                           .where(search_conditions)
                           .select { |ml| can? :create, ml.subscriptions.new }

      respond_to do |format|
        format.json { render json: for_typeahead(entries) }
      end
    end

    private

    def people
      @people ||= Person.where(id: people_ids).distinct
    end

    def non_subscribed_people
      Person.where(id: non_subscribed_people_ids)
    end

    def non_subscribed_people_ids
      people.pluck(:id) -
        mailing_list.subscriptions
                    .where(subscriber_type: Person.sti_name)
                    .pluck(:subscriber_id)
    end

    def group
      @group ||= Group.find(params[:group_id])
    end

    def people_ids
      list_param(:ids)
    end

    def self.model_class
      Subscription
    end

    def for_typeahead(entries)
      entries.map do |entry|
        { id: entry.id, label: entry.name }
      end
    end

    def mailing_list
      @mailing_list ||= MailingList.find(params[:mailing_list_id])
    end

    def build_new_subscriptions
      non_subscribed_people.map do |person|
        subscription = mailing_list.subscriptions.new
        subscription.subscriber_id = person.id
        subscription.subscriber_type = Person.sti_name
        subscription
      end
    end

    def flash_message(type, attrs = {})
      attrs[:mailing_list] = mailing_list.name
      I18n.t("mailing_lists.subscriber_lists.#{action_name}.#{type}", **attrs)
    end
  end
end
