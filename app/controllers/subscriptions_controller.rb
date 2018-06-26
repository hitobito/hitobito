# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SubscriptionsController < CrudController

  include Concerns::RenderPeopleExports
  include Concerns::AsyncDownload

  self.nesting = Group, MailingList

  decorates :group

  prepend_before_action :parent

  alias mailing_list parent

  def index # rubocop:disable Metrics/MethodLength there are a lof of formats supported
    respond_to do |format|
      format.html do
        @person_add_requests = fetch_person_add_requests
        load_grouped_subscriptions
      end
      format.pdf   { render_pdf(ordered_people, parents.first) }
      format.csv   { render_tabular_in_background(:csv)  && redirect_to(action: :index) }
      format.xlsx  { render_tabular_in_background(:xlsx) && redirect_to(action: :index) }
      format.vcf   { render_vcf(ordered_people.includes(:phone_numbers, :additional_emails)) }
      format.email { render_emails(ordered_people.includes(:additional_emails)) }
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

  # Override so we can pass preferred_labels from mailing_list
  def render_emails(people)
    emails = Person.mailing_emails_for(people, parent.labels)
    render text: emails.join(',')
  end

  def render_tabular_in_background(format)
    with_async_download_cookie(format, "subscriptions_#{mailing_list.id}") do |filename|
      Export::SubscriptionsJob.new(format,
                                   current_person.id,
                                   mailing_list.id,
                                   params.slice(:household).merge(filename: filename)).enqueue!
    end
  end

  def prepare_tabular_entries(people)
    people.preload_public_accounts.includes(roles: :group)
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
