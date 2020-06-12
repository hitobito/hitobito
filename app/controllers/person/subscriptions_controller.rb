#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::SubscriptionsController < ApplicationController

  skip_authorization_check

  def index
    authorize!(:show_details, person)
    @group = Group.find(params[:group_id])

    @subscribed = Person::Subscriptions.new(person).mailing_lists.includes(:group).list
    @subscribable = MailingList.includes(:group).subscribable.where.not(id: @subscribed)
  end

  def create
    authorize!(:update, person)
    create_subscription
    redirect_with_notice
  end

  def destroy
    authorize!(:update, person)
    delete_subscription || create_subscription(excluded: true)
    redirect_with_notice
  end

  private

  def redirect_with_notice
    group = Group.find(params[:group_id])
    message = t('.success', mailing_list: mailing_list, person: person)
    redirect_to group_person_subscriptions_path(group, person), notice: message
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def mailing_list
    @mailing_list ||= MailingList.find(params[:id])
  end

  def delete_subscription
    mailing_list.subscriptions.find_by(subscriber: person)&.destroy
  end

  def create_subscription(options = {})
    mailing_list.subscriptions.create(options.merge(subscriber: person))
  end
end

