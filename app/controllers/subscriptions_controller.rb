# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SubscriptionsController < CrudController

  include Concerns::RenderPeopleExports

  self.nesting = Group, MailingList

  decorates :group

  prepend_before_action :parent

  alias_method :mailing_list, :parent


  def index
    respond_to do |format|
      format.html do
        @person_add_requests = fetch_person_add_requests
        load_grouped_subscriptions
      end
      format.pdf   { render_pdf(ordered_people) }
      format.csv   { render_csv(ordered_people) }
      format.email { render_emails(ordered_people) }
    end
  end

  private

  def load_grouped_subscriptions
    @group_subs = group_subscriptions
    @person_subs = person_subscriptions
    @event_subs = event_subscriptions
    @excluded_person_subs = person_subscriptions(true)
  end

  def ordered_people
    mailing_list.people.order_by_name
  end

  def render_csv(people)
    csv = Export::Csv::People::PeopleAddress.export(people)
    send_data csv, type: :csv
  end

  def group_subscriptions
    subscriptions_for_type(Group).
      includes(:related_role_types).
      order('groups.name')
  end

  def person_subscriptions(excluded = false)
    subscriptions_for_type(Person).
      where(excluded: excluded).
      order('people.last_name', 'people.first_name')
  end

  def event_subscriptions
    subscriptions_for_type(Event).order('events.name')
  end

  def subscriptions_for_type(klass)
    mailing_list.subscriptions.
      where(subscriber_type: klass.name).
      joins("INNER JOIN #{klass.table_name} " \
            "ON #{klass.table_name}.id = subscriptions.subscriber_id").
      includes(:subscriber)
  end

  def authorize_class
    if html_request?
      authorize!(:index_subscriptions, mailing_list)
    else
      authorize!(:export_subscriptions, mailing_list)
    end
  end

  def fetch_person_add_requests
    if can?(:create, mailing_list.subscriptions.new)
      @mailing_list.person_add_requests.list.includes(person: :primary_group)
    end
  end

end
