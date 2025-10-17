#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::SubscriptionsController < ApplicationController
  skip_authorization_check
  helper_method :subscribable?, :person

  before_action :authorize_person, only: [:create, :destroy]

  def index
    authorize!(:show_details, person)
    @group = Group.find(params[:group_id])
    @grouped_subscribed = grouped_by_layer(subscribed)
    @grouped_subscribable = grouped_by_layer(subscribable - subscribed)
  end

  def create
    subscriptions.create(mailing_list)
    redirect_with_notice
  end

  def destroy
    subscriptions.destroy(mailing_list)
    redirect_with_notice
  end

  private

  def redirect_with_notice
    group = Group.find(params[:group_id])
    message = t(".success", mailing_list: mailing_list, person: person)
    redirect_to group_person_subscriptions_path(group, person), notice: message
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def mailing_list
    @mailing_list ||= subscriptions.subscribable.find(params[:id])
  end

  def subscribable?(list)
    subscribable.include?(list)
  end

  def subscribed
    @subscribed ||= subscriptions.subscribed.includes(group: :layer_group).list.to_a
  end

  def subscribable
    @subscribable ||= subscriptions.subscribable.includes(group: :layer_group).list.to_a
  end

  def subscriptions
    @subscriptions ||= Person::Subscriptions.new(person)
  end

  def grouped_by_layer(mailing_lists)
    mailing_lists.group_by { _1.group.layer_group }
  end

  def authorize_person
    authorize!(:update, person)
  end
end
