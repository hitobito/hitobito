#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::SubscriptionsController < ApplicationController
  skip_authorization_check
  helper_method :subscribed, :subscribable, :subscribable_ancestors_only, :person

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
    message = t(".success", mailing_list: mailing_list, person: person)
    redirect_to group_person_subscriptions_path(group, person), notice: message
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def mailing_list
    @mailing_list ||= MailingList.find(params[:id])
  end

  def subscribed
    @subscribed ||= grouped_by_layer(subscriptions.subscribed)
  end

  def subscribable
    @subscribable ||= grouped_by_layer(subscriptions.subscribable - subscriptions.subscribed)
  end

  def subscribable_ancestors_only
    @subscribable_ancestors_only ||= grouped_by_layer(subscriptions.subscribable_ancestors_only(@group) - subscriptions.subscribed)
  end

  def subscriptions
    @subscriptions ||= Person::Subscriptions.new(person)
  end

  def grouped_by_layer(mailing_lists)
    layer_order = Group.all_types.select(&:layer).map(&:name)
    MailingList
      .includes(group: :layer_group)
      .list
      .where(id: mailing_lists.map(&:id))
      .group_by { _1.group.layer_group }
      .sort_by { |layer, _lists| [layer_order.index(layer.class.name) || Float::INFINITY, layer.lft] }
  end
end
