#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::SubscriptionsController < ApplicationController

  skip_authorization_check
  helper_method :subscribed, :subscribable

  def index
    authorize!(:show_details, person)
    @group = Group.find(params[:group_id])
  end

  def create
    authorize!(:update, person)
    subscriptions.create(mailing_list)
    redirect_with_notice
  end

  def destroy
    authorize!(:update, person)
    subscriptions.destroy(mailing_list)
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

  def subscribed
    @subscribed ||= grouped_by_layer(subscriptions.subscribed.list)
  end

  def subscribable
    @subscribable ||= grouped_by_layer(
      subscriptions.subscribable.where.not(id: subscriptions.subscribed).list
    )
  end

  def subscriptions
    @subscriptions ||= Person::Subscriptions.new(person)
  end

  def grouped_by_layer(mailing_lists)
    mailing_lists.includes(:group).group_by { _1.group.layer_group }
  end

end
